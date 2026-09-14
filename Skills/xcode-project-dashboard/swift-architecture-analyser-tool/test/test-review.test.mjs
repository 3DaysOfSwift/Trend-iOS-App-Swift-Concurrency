import test from 'node:test';
import assert from 'node:assert/strict';
import {renderTestReview,testQualityRating,renderTestRating} from '../src/test-review.mjs';
test('test rating uses the same score for fractional stars and thresholds',()=>{
 const scenarios=(matched,total)=>Array.from({length:total},(_,i)=>({status:i<matched?'identified':'not-identified'}));
 for(const [matched,total,score,stars] of [[8,14,57,2.85],[4,5,80,4],[5,5,100,5],[0,5,0,0]]) {
   const rating=testQualityRating(scenarios(matched,total));
   assert.equal(rating.score,score);
   assert.equal(rating.stars,stars);
   assert.equal(rating.colour,score>=80?'#75dfaa':'#ff8d8d');
 }
 assert.equal(testQualityRating([]).score,null);
 assert.match(renderTestRating({scenarios:[]}),/Not rated/);
 assert.match(renderTestRating({scenarios:scenarios(4,5)}),/width:80%/);
});
test('test review counts scenarios, escapes source and distinguishes suggestions',()=>{
 const item={title:'A < B',detail:'Behaviour',evidence:[{file:'Tests/T.swift',line:4,excerpt:'#expect(a < b)'}]};
 const html=renderTestReview({scope:'Partial',scenarios:[{...item,status:'identified'},{...item,status:'not-identified'}],concerns:[item],keep:item});
 assert.match(html,/<strong>1 \/ 2<\/strong>/);
 assert.match(html,/A &lt; B/);
 assert.match(html,/#expect\(a &lt; b\)/);
 assert.match(html,/not code coverage/);
 assert.match(html,/No tests recommended for automatic removal/);
 assert.match(html,/T.swift · Line 4/);
});
