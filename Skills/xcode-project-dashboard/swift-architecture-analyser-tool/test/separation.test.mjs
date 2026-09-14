import test from 'node:test';
import assert from 'node:assert/strict';
import {separation} from '../src/separation.mjs';
test('separation distinguishes unknown, no boundary and reviewed business decisions',()=>{
  assert.equal(separation().value,null);
  assert.equal(separation({complete:false}).value,null);
  assert.equal(separation({complete:true,hasTestableModel:false,decisions:[]}).value,0);
  const review={complete:true,hasTestableModel:true,decisions:[{location:'model',testable:true},{location:'viewmodel',testable:true}]};
  assert.equal(separation(review).value,50);
  review.decisions.pop();
  assert.equal(separation(review).value,100);
});
test('scoped rating stays explicit without claiming a complete review',()=>{
  const review={complete:false,ratingScope:'reviewed-rules',hasTestableModel:true,decisions:[...Array.from({length:35},()=>({location:'model',testable:true})),{location:'ui',testable:false},{location:'ui',testable:false}]};
  const score=separation(review);
  assert.equal(score.value,95);
  assert.equal(score.partial,true);
  assert.match(score.reason,/35 of 37/);
  assert.match(score.reason,/not an exhaustive/);
  assert.equal(separation({...review,decisions:[]}).value,null);
});
