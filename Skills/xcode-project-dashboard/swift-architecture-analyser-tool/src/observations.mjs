import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
const creationKinds = new Set(['task','detached','async-let','group-child','view-task','refresh']);
export function observationCoverage(report) {
  const sites = report.files.flatMap(f=>f.sites).filter(s=>creationKinds.has(s.kind));
  const journeys = report.observations?.journeys ?? [];
  const documented = new Set(journeys.map(j=>j.siteId));
  return { total: sites.length, documented: documented.size,
    remaining: sites.filter(s=>!documented.has(s.id)), journeys: journeys.length };
}

// Validation checks provenance and structure, not the truth of an author's claims.
export function attachObservations(report, input) {
  const fail = message => { throw new Error('Invalid observations: '+message); };
  const text = value => typeof value === 'string' && value.trim().length > 0;
  if (!input || input.schemaVersion !== 1) fail('schemaVersion must be 1');
  if (!report.sourceFingerprint || input.sourceFingerprint !== report.sourceFingerprint) fail('source fingerprint differs; regenerate and review against the current scan');
  if (!text(input.author) || !text(input.scope) || !text(input.createdAt) || !Number.isFinite(Date.parse(input.createdAt))) fail('author, scope and valid createdAt required');
  if (!Array.isArray(input.journeys)) fail('journeys must be an array');
  const sites = new Map(report.files.flatMap(f=>f.sites).filter(s=>creationKinds.has(s.kind)).map(s=>[s.id,s]));
  const files = new Map(report.files.map(f=>[f.path,f]));
  const ids = new Set(), covered = new Set();
  for (const journey of input.journeys) {
    if (!text(journey.id) || ids.has(journey.id)) fail('unique journey id required');
    ids.add(journey.id);
    if (!sites.has(journey.siteId) || covered.has(journey.siteId)) fail('unique scanned creation/entry site required per journey');
    covered.add(journey.siteId);
    if (!text(journey.title) || !text(journey.scope)) fail('journey title and scope required');
    if (!Array.isArray(journey.unknowns) || !journey.unknowns.every(text)) fail('unknowns must be a string array');
    if (!Array.isArray(journey.steps) || !journey.steps.length) fail('at least one step required');
    for (const step of journey.steps) {
      if (!text(step.action) || !text(step.task) || !text(step.context)) fail('step action, task and context required');
      if (!Array.isArray(step.evidence) || !step.evidence.length) fail('source evidence required for every step');
      for (const ref of step.evidence) {
        const file = files.get(ref.file);
        if (!file || !Number.isInteger(ref.line) || !Number.isInteger(ref.endLine) || ref.line < 1 || ref.endLine < ref.line || ref.endLine > file.lineCount) fail('invalid evidence path or line range');
      }
    }
  }
  if (input.separation !== undefined) {
    const review=input.separation;
    if (!review || typeof review.complete!=='boolean' || typeof review.hasTestableModel!=='boolean' || !text(review.rationale) || !Array.isArray(review.decisions)) fail('invalid separation review');
    if (review.ratingScope !== undefined && review.ratingScope !== 'reviewed-rules') fail('invalid separation rating scope');
    const decisionIDs=new Set();
    for(const d of review.decisions) {
      if (!text(d.id) || decisionIDs.has(d.id) || !text(d.description) || !['ui','viewmodel','model','other'].includes(d.location) || typeof d.testable!=='boolean') fail('invalid decision classification');
      decisionIDs.add(d.id);
      if (d.testStatus !== undefined && !['identified','not-identified','unknown'].includes(d.testStatus)) fail('invalid test status');
      if (d.testStatus === 'identified' && !text(d.testReference)) fail('identified test requires a testReference');
      if (d.testNote !== undefined && !text(d.testNote)) fail('testNote must be text');
      if(!Array.isArray(d.evidence) || !d.evidence.length) fail('decision evidence required');
      for(const ref of d.evidence) {
        const file=files.get(ref.file);
        if(!file || !Number.isInteger(ref.line) || !Number.isInteger(ref.endLine) || ref.line<1 || ref.endLine<ref.line || ref.endLine>file.lineCount) fail('invalid decision evidence');
      }
    }
  }
  return {...report, observations: input};
}

export async function readObservationEvidence(report, root) {
  const cache = new Map();
  const references = [
    ...(report.observations?.journeys ?? []).flatMap(j=>j.steps.flatMap(s=>s.evidence)),
    ...(report.observations?.separation?.decisions ?? []).flatMap(d=>d.evidence)
  ];
  for (const ref of references) {
      if (!cache.has(ref.file)) {
        const source = await fs.readFile(path.join(root, ref.file), 'utf8');
        if (createHash('sha256').update(source).digest('hex') !== report.files.find(f=>f.path===ref.file).hash)
          throw new Error('Source changed while reading observations; scan again.');
        cache.set(ref.file, source.split('\n'));
      }
      ref.excerpt = cache.get(ref.file).slice(ref.line-1, ref.endLine).join('\n');
  }
  return report;
}
