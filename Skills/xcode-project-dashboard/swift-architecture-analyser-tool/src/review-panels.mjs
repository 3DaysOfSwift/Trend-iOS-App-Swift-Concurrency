import {renderTestReview,renderTestRating} from './test-review.mjs';
const esc=v=>String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function reviewPanels(review) {
  if(!review) return {dashboard:'',detail:''};
  const source=r=>'<p class="path" title="'+esc(r.file)+'">'+esc(r.file.split('/').pop())+' · Line '+r.line+'</p><pre>'+r.excerpt.split('\n').map((l,i)=>'<span class="code-line '+(!i?'code-focus':'')+'"><span class="line-number">'+(r.line+i)+'</span>'+esc(l)+'</span>').join('')+'</pre>';
  const findings=(review.findings??[]).map(f=>'<details class="review"><summary style="color:var(--amber)">'+esc(f.title)+'</summary><span class="tag">'+esc(f.status)+'</span><p>'+esc(f.description)+'</p>'+f.evidence.map(source).join('')+'<p><strong>Suggested check:</strong> '+esc(f.check)+'</p></details>').join('');
  return {dashboard:(review.testQuality?.scenarios.length?renderTestRating(review.testQuality):'')+'<p><button id="show-authored-review" class="control">Review findings and test scenarios →</button></p>',detail:'<section id="authored-review"><h2>⚠️ Reviewed Code Investigations</h2><p class="small">'+esc(review.scope)+'</p>'+findings+'</section>'+(review.testQuality?renderTestReview(review.testQuality):'')};
}
