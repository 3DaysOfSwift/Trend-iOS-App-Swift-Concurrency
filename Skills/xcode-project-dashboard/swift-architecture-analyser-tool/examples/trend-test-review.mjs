import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';

// Authored, bounded review. Counts are scenario groups, never line coverage.
export async function reviewTrendTests(root, productionFiles) {
  async function walk(dir) {
    const entries=await fs.readdir(dir,{withFileTypes:true});
    return (await Promise.all(entries.map(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]))).flat();
  }
  const tests=await walk(path.join(root,'TrendTests'));
  const paths=[...productionFiles.map(f=>path.join(root,f.path)),...tests];
  const hashes=new Map();
  async function evidence(name,needle,length=18) {
    const matches=paths.filter(p=>path.basename(p)===name);
    if(matches.length!==1) throw Error('Missing or ambiguous test-review file: '+name);
    const raw=await fs.readFile(matches[0],'utf8'),lines=raw.split('\n');
    const line=lines.findIndex(l=>l.includes(needle))+1;
    if(!line) throw Error('Missing test-review evidence: '+needle);
    const file=path.relative(root,matches[0]);
    hashes.set(file,createHash('sha256').update(raw).digest('hex'));
    return {file,line,endLine:Math.min(lines.length,line+length-1),excerpt:lines.slice(line-1,line+length-1).join('\n')};
  }
  const scenarios=[];
  async function scenario(title,status,detail,name,needle,length=18) {
    scenarios.push({title,status,detail,evidence:[await evidence(name,needle,length)]});
  }
  await scenario('Overlapping habit additions preserve both values','identified','The test pauses storage and asserts both returned counts plus the final persisted value.','HabitsWorkerIntegrationTests.swift','@Test func overlappingRecordingsPreserveBothValues',25);
  await scenario('Shared habit loading survives a cancelled caller','identified','The helper asserts one storage load, four completed callers and the expected final load state.','HabitsWorkerIntegrationTests.swift','private func checkSharedLoad',36);
  await scenario('Failed habit save preserves state and releases the next operation','identified','A failed write leaves the old value visible; the next write succeeds.','HabitsWorkerIntegrationTests.swift','@Test func failedSavePreservesPublishedValues',25);
  await scenario('Successful persistence still publishes after cancellation','identified','Cancellation arrives while the save is suspended; stored and visible entries must agree.','HabitsWorkerIntegrationTests.swift','@Test func successfulSaveStillPublishes',18);
  await scenario('Completed checkout unlocks the feature','identified','A fake purchase client exercises the manager command and entitlement publication, not live StoreKit.','PurchaseManagerTests.swift','@Test func completedPurchaseUnlocksHabits',12);
  await scenario('Cancelled checkout leaves access locked without a message','identified','Both access state and absence of messaging are asserted.','PurchaseManagerTests.swift','@Test func cancelledPurchaseLeavesHabitsLocked',14);
  await scenario('Product metadata failure does not hide an existing entitlement','identified','The test injects metadata failure and checks entitlement, absent product and error presentation.','PurchaseManagerTests.swift','@Test func entitlementLoadsWhenProductMetadataFails',14);
  await scenario('History deletion failure preserves the entry and presents the error','identified','The failed repository write is reflected in both retained data and the ViewModel message.','HistoryViewModelTests.swift','@Test func deleteFailureIsPresented',19);
  await scenario('Overlapping weight edits preserve both changes','not-identified','No focused overlap test identified in WeightLogManagerTests or the test-name search. Pause the first save, submit another edit, then inspect durable and published state.','WeightLogManager.swift','func add',16);
  await scenario('Older weight refresh cannot replace a newer save','not-identified','Existing tests cover early cached publication, not a refresh completing after a newer mutation. Control synchronization completion order.','WeightLogManager.swift','let synchronizedStore',7);
  await scenario('Repeated checkout follows an explicit single-checkout policy','not-identified','No overlap assertion in PurchaseManagerTests. Decide ignore or share semantics, then assert client call count and busy-state lifetime with paused requests.','PurchaseManager.swift','func purchaseHabits',19);
  await scenario('Pending checkout explains approval without unlocking','not-identified','The pending branch has no direct test in PurchaseManagerTests. Delayed-approval testing exercises a different path.','PurchaseManager.swift','case .pending:',7);
  await scenario('Delete-all has an explicit cross-feature scope','not-identified','The existing test seeds weights only. Decide whether all includes habits; seed both and assert the intended scope before treating the result as a failure.','SettingsManager.swift','func deleteAllData',7);
  await scenario('Imported entries follow agreed date and value constraints','not-identified','The picker-error test does not exercise decoded file contents. Test valid JSON containing invalid domain values against the agreed reject or normalize policy.','SettingsManager.swift','func importData',7);
  const concerns=[
    {title:'Does changing the range change the displayed data?',detail:'changingRangeDelegatesToProgressFeature uses an empty data set and checks the range plus idle state. It verifies some forwarding, but could still pass if range storage worked while recalculation was removed. Strengthen it with dated entries inside and outside the range and assert the resulting points. Do not delete it as redundant.',evidence:[await evidence('ProgressViewModelTests.swift','@Test func changingRangeDelegatesToProgressFeature',17),await evidence('ProgressManager.swift','func selectProgressRange',8)]},
    {title:'Does export preserve the intended data?',detail:'exportProducesJSONDocumentAndOpensExporter checks a document exists and exporter presentation, but never decodes the payload. Useful UI-state protection; incomplete protection for the export behaviour. Add a decode-and-compare assertion for entries and goal.',evidence:[await evidence('SettingsViewModelTests.swift','@Test func exportProducesJSONDocumentAndOpensExporter',16),await evidence('SettingsManager.swift','func exportData',4)]}
  ];
  const keep={title:'Keep the theme persistence test',detail:'This is not a trivial assignment/readback check. It constructs a second ThemeManager with the same preferences and verifies the saved selection survives reconstruction. Removing persistence would break this test.',evidence:[await evidence('ThemeManagerTests.swift','@Test func remembersTheSelectedTheme',10)]};
  return {scope:'Targeted first pass: habit operation coordination, weight persistence, purchases, history failures, settings import/export/deletion, progress-range behaviour and theme persistence. Not an exhaustive audit of all 114 tests. Test names were searched across TrendTests; assertions were read for the evidence below. No mutation testing was performed.',scenarios,concerns,keep,evidenceHashes:Object.fromEntries(hashes)};
}
