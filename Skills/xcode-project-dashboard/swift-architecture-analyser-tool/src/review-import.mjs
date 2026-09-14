import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';

// Review judgments are authored; validation establishes provenance, not truth.
export async function importReview(report,input,root) {
  const text=v=>typeof v==='string' && v.trim().length>0;
  const fail=m=>{throw Error('Invalid architecture review: '+m)};
  if(input?.schemaVersion!==1 || input.sourceFingerprint!==report.sourceFingerprint) fail('schema or source fingerprint mismatch');
  if(!text(input.scope)||!text(input.author)) fail('scope and author required');
  const review=structuredClone(input), refs=[];
  const list=(items,fields)=>{
    if(!Array.isArray(items)) fail('expected review list');
    for(const item of items) {
      if(!item||!fields.every(k=>text(item[k]))) fail('missing review text');
      if(!Array.isArray(item.evidence)||!item.evidence.length) fail('source evidence required');
      refs.push(...item.evidence);
    }
  };
  list(review.findings??[],['title','status','description','check']);
  if(review.concurrencyChecks) {
    list(review.concurrencyChecks,['siteId','title','status','path','trigger','navigation','repetition','lifetime','effect','conclusion','verification']);
    const entries=new Map(report.files.flatMap(f=>f.sites).filter(s=>['task','detached','view-task','refresh'].includes(s.kind)).map(s=>[s.id,s]));
    const seen=new Set();
    for(const c of review.concurrencyChecks) {
      if(!entries.has(c.siteId)||seen.has(c.siteId)) fail('invalid or duplicate concurrency entry');
      seen.add(c.siteId);
      if(!['warning','managed','unresolved'].includes(c.status)) fail('invalid concurrency outcome');
      const entry=entries.get(c.siteId);
      if(!c.evidence.some(e=>e.file===entry.file&&e.line<=entry.line&&e.endLine>=entry.line)) fail('concurrency evidence must include its trigger');
    }
  }
  if(review.taskLifetimes) {
    list(review.taskLifetimes,['siteId','handle','creator','wait','cancellation','policy']);
    const roots=new Map(report.files.flatMap(f=>f.sites).filter(s=>['task','detached'].includes(s.kind)).map(s=>[s.id,s]));
    const seen=new Set();
    for(const r of review.taskLifetimes) {
      if(!roots.has(r.siteId)||seen.has(r.siteId)) fail('invalid or duplicate root Task');
      seen.add(r.siteId);
      for(const [key,values] of Object.entries({handle:['tracked','untracked','unknown'],creator:['task','synchronous','unknown'],wait:['awaited','not-awaited','not-applicable','unknown'],cancellation:['forwarded','not-forwarded','not-applicable','unknown']}))if(!values.includes(r[key]))fail('invalid lifetime '+key);
      if(r.creator==='synchronous'&&(r.wait!=='not-applicable'||r.cancellation!=='not-applicable'))fail('synchronous creator has no creating Task relationship');
      if(r.creator==='task'&&(r.wait==='not-applicable'||r.cancellation==='not-applicable'))fail('creating Task requires wait and cancellation review');
    }
  }
  const q=review.testQuality;
  if(q) {
    if(!text(q.scope)) fail('test review scope required');
    list(q.scenarios,['title','status','detail']);
    if(new Set(q.scenarios.map(s=>s.title)).size!==q.scenarios.length) fail('duplicate scenario');
    if(q.scenarios.some(s=>!['identified','not-identified'].includes(s.status))) fail('unsupported scenario status');
    list(q.concerns??[],['title','detail']);
    list(q.keep?[q.keep]:[],['title','detail']);
    q.concerns??=[];
  }
  const base=await fs.realpath(root),cache=new Map();
  const hashes=new Map(report.files.map(f=>[f.path,f.hash]));
  for(const ref of refs) {
    if(!text(ref.file)||path.isAbsolute(ref.file)||ref.file.split(/[\\/]/).includes('..')) fail('evidence must stay inside repository');
    if(!cache.has(ref.file)) {
      const real=await fs.realpath(path.join(base,ref.file));
      if(!real.startsWith(base+path.sep)) fail('evidence symlink escapes repository');
      const source=await fs.readFile(real,'utf8');
      const expected=hashes.get(ref.file)??review.evidenceHashes?.[ref.file];
      if(!expected||createHash('sha256').update(source).digest('hex')!==expected) fail('evidence hash mismatch: '+ref.file);
      cache.set(ref.file,source.split('\n'));
    }
    const lines=cache.get(ref.file);
    if(!Number.isInteger(ref.line)||!Number.isInteger(ref.endLine)||ref.line<1||ref.endLine<ref.line||ref.endLine>lines.length) fail('invalid evidence lines');
    ref.excerpt=lines.slice(ref.line-1,ref.endLine).join('\n');
  }
  return review;
}
