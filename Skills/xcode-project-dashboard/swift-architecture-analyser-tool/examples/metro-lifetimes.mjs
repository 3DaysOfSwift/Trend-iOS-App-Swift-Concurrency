// Authored lifecycle evidence for this Metro snapshot, not scanner heuristics.
import fs from 'node:fs/promises';
import path from 'node:path';
const r=JSON.parse(await fs.readFile('reports/metro-dashboard/report.json','utf8'));
const review=structuredClone(r.reviewData);
delete review.testQuality; // Prior sampled rating is not a complete project review.
review.scope='Task lifetime update. Full architecture analysis remains incomplete; project ratings withheld.';
review.taskLifetimes=[];
for(const f of r.files)for(const s of f.sites.filter(s=>s.kind==='task')){
 const name=path.basename(f.path),lines=(await fs.readFile(path.join('../metro-mate-ios',f.path),'utf8')).split('\n');
 const button=['ContentView.swift','BeatPresetsView.swift'].includes(name);
 const waited=name==='MetronomeManager.swift'&&[99,187,538,565,602].includes(s.line);
 const policy=button?'Synchronous Button/onDelete bridge. No retained handle here; downstream feature work has its own ordering/load policies. Another event does not automatically cancel this bridge.':waited?'The caller joins this retained operation, directly or through the save worker. Cancellation is not automatically forwarded: shared loads and submitted persistence/audio operations have explicitly managed lifetimes. This is a relationship to inspect, not proof of a defect.':'Handle retained by the ViewModel, feature or scheduler. Creating-context relationships across all callers have not been fully resolved; waiting and cancellation counts exclude this unresolved case.';
 review.taskLifetimes.push({siteId:s.id,handle:button?'untracked':'tracked',creator:button?'synchronous':waited?'task':'unknown',wait:button?'not-applicable':waited?'awaited':'unknown',cancellation:button?'not-applicable':waited?'not-forwarded':'unknown',policy,evidence:[{file:f.path,line:Math.max(1,s.line-4),endLine:Math.min(lines.length,s.line+35)}]});
}
await fs.mkdir('reports/metro-lifetime-inputs');
await fs.writeFile('reports/metro-lifetime-inputs/review.json',JSON.stringify(review,null,2),{flag:'wx'});
