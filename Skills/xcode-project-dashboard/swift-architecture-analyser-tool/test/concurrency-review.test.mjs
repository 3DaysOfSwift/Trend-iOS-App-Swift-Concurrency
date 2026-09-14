import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {analyse} from '../src/analyse.mjs';
import {importReview} from '../src/review-import.mjs';
import {concurrencyReview} from '../src/concurrency-review.mjs';

test('operation review binds to a real trigger and reloads source evidence',async()=>{
  const root=await fs.mkdtemp(path.join(os.tmpdir(),'concurrency-review-'));
  try {
    await fs.writeFile(path.join(root,'EditorView.swift'),'Text("Editor").task { await model.save() }\nfunc unrelated() {}\n');
    const report=await analyse(root);
    const trigger=report.files[0].sites.find(s=>s.kind==='view-task');
    const check={siteId:trigger.id,title:'Could leaving interrupt saving?',status:'warning',path:'View → save',trigger:'View appearance',navigation:'Cancellation requested',repetition:'New lifetime can repeat',lifetime:'Direct await',effect:'Write may already have committed',conclusion:'Inspect partial writes',verification:'Source only',evidence:[{file:'EditorView.swift',line:1,endLine:1,excerpt:'untrusted'}]};
    const input={schemaVersion:1,sourceFingerprint:report.sourceFingerprint,author:'Test',scope:'Fixture',concurrencyChecks:[check]};
    const imported=await importReview(report,input,root);
    assert.match(imported.concurrencyChecks[0].evidence[0].excerpt,/model.save/);
    assert.doesNotMatch(imported.concurrencyChecks[0].evidence[0].excerpt,/untrusted/);
    for(const change of [{siteId:'missing'},{status:'safe-forever'},{navigation:''},{evidence:[{file:'EditorView.swift',line:2,endLine:2}]}]) {
      await assert.rejects(importReview(report,{...input,concurrencyChecks:[{...check,...change}]},root),/Invalid architecture review/);
    }
    await assert.rejects(importReview(report,{...input,concurrencyChecks:[check,check]},root),/duplicate/);
  } finally {await fs.rm(root,{recursive:true,force:true});}
});

test('managed and unresolved operations are not counted as warnings; unreviewed is not safe',()=>{
  const base={title:'<script>',path:'A → B',evidence:[{file:'A.swift',line:1,excerpt:'Task { }'}]};
  const result=concurrencyReview(['warning','managed','unresolved'].map(status=>({...base,status})));
  assert.deepEqual(result.counts,{warning:1,managed:1,unresolved:1});
  assert.ok(result.html.indexOf('<pre>')<result.html.indexOf('Call path:'));
  assert.ok(!result.html.includes('<script>'));
  assert.match(concurrencyReview().html,/does not mean there are no concurrency risks/);
});
