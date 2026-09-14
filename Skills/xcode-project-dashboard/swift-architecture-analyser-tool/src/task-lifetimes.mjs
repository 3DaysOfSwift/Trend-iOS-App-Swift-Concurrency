// A Task initializer starts an independent root, even inside another Task.
// Waiting/forwarding are reviewed relationships, not inferred from indentation.
export function taskLifetimes(files, reviews=[]) {
  const roots=files.flatMap(f=>f.sites).filter(s=>['task','detached'].includes(s.kind));
  const byId=new Map(reviews.map(r=>[r.siteId,r]));
  const make=(id,label,predicate,detail)=>({id,label,value:roots.filter(predicate).length,kinds:['task','detached'],siteIds:roots.filter(predicate).map(s=>s.id),detail});
  return [
    make('root-tasks','Root Tasks',()=>true,'Task and Task.detached create independent roots, even when another Task creates them. SwiftUI-owned Tasks are counted separately.'),
    make('tracked-roots','Tracked root Tasks',s=>byId.get(s.id)?.handle==='tracked','Reviewed roots whose handle is retained for lifetime management. Storage alone does not apply cancellation.'),
    make('untracked-roots','Untracked root Tasks',s=>byId.get(s.id)?.handle==='untracked','Reviewed roots without a retained handle. A synchronous button bridge can legitimately be untracked.'),
    make('creator-not-waiting','Creator does not wait',s=>byId.get(s.id)?.creator==='task'&&byId.get(s.id)?.wait==='not-awaited','An existing Task creates this root but does not await completion. Inspect whether independent completion is intended.'),
    make('cancellation-not-forwarded','Cancellation not forwarded',s=>byId.get(s.id)?.creator==='task'&&byId.get(s.id)?.cancellation==='not-forwarded','Cancellation of an existing creating Task is not forwarded. Intentional shared work is distinguished in its policy notes.'),
    make('lifetime-unresolved','Lifetime checks unresolved',s=>{const r=byId.get(s.id);return !r||r.handle==='unknown'||r.creator==='unknown'||(r.creator==='task'&&(r.wait==='unknown'||r.cancellation==='unknown'));},'These roots need further lifecycle inspection. They are not counted as confirmed waiting or cancellation gaps.')
  ];
}
