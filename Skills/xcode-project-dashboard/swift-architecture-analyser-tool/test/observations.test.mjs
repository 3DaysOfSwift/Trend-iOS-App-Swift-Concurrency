import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { analyse } from '../src/analyse.mjs';
import { attachObservations, observationCoverage, readObservationEvidence } from '../src/observations.mjs';

test('observations bind to source, validate evidence, and count unique documented sites',async()=>{
  const root=await fs.mkdtemp(path.join(os.tmpdir(),'observations-'));
  try {
    await fs.writeFile(path.join(root,'App.swift'),'Task { await load() }\nTask { await save() }');
    const report=await analyse(root);
    const site=report.files[0].sites.find(s=>s.kind==='task');
    const input={schemaVersion:1,sourceFingerprint:report.sourceFingerprint,author:'Test',createdAt:'2026-09-13',scope:'Partial',journeys:[{id:'load',siteId:site.id,title:'Load',scope:'One call',unknowns:['Implementation'],steps:[{action:'Await load',task:'Load',context:'Not resolved',evidence:[{file:'App.swift',line:1,endLine:1}]}]}]};
    const joined=attachObservations(report,structuredClone(input));
    assert.equal(observationCoverage(joined).documented,1);
    assert.equal(observationCoverage(joined).remaining.length,1);
    await readObservationEvidence(joined,root);
    assert.equal(joined.observations.journeys[0].steps[0].evidence[0].excerpt,'Task { await load() }');
    const decisionInput={...structuredClone(input),separation:{complete:false,hasTestableModel:true,rationale:'Fixture',decisions:[{id:'rule',description:'Rule',location:'model',testable:true,testStatus:'not-identified',evidence:[{file:'App.swift',line:2,endLine:2,excerpt:'Do not trust this supplied excerpt'}]}]}};
    const decisionReport=attachObservations(report,decisionInput);
    await readObservationEvidence(decisionReport,root);
    assert.equal(decisionReport.observations.separation.decisions[0].evidence[0].excerpt,'Task { await save() }');
    decisionInput.separation.decisions[0].testStatus='identified';
    assert.throws(()=>attachObservations(report,decisionInput),/testReference/);
    for (const mutate of [
      v=>v.sourceFingerprint='stale',
      v=>v.journeys.push(v.journeys[0]),
      v=>v.journeys[0].siteId='missing',
      v=>v.journeys[0].steps[0].evidence[0].file='../outside.swift',
      v=>v.journeys[0].steps[0].evidence[0].endLine=900,
      v=>v.journeys[0].steps[0].evidence=[]
    ]) {
      const bad=structuredClone(input);mutate(bad);
      assert.throws(()=>attachObservations(report,bad),/Invalid observations/);
    }
    await fs.writeFile(path.join(root,'App.swift'),'Task { await changed() }');
    assert.notEqual((await analyse(root)).sourceFingerprint,report.sourceFingerprint);
    await assert.rejects(()=>readObservationEvidence(joined,root),/Source changed/);
  } finally {await fs.rm(root,{recursive:true,force:true});}
});
