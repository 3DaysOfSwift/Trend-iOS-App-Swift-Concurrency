import test from 'node:test';
import assert from 'node:assert/strict';
import {taskLifetimes} from '../src/task-lifetimes.mjs';
test('tracking, waiting and cancellation remain independent classifications',()=>{
 const files=[{sites:['a','b','c','d'].map(id=>({id,kind:'task'})).concat({id:'child',kind:'async-let'})}];
 const reviews=[{siteId:'a',handle:'untracked',creator:'synchronous',wait:'not-applicable',cancellation:'not-applicable'}, {siteId:'b',handle:'tracked',creator:'task',wait:'awaited',cancellation:'not-forwarded'}, {siteId:'c',handle:'tracked',creator:'task',wait:'not-awaited',cancellation:'forwarded'}];
 const metrics=Object.fromEntries(taskLifetimes(files,reviews).map(m=>[m.id,m]));
 assert.equal(metrics['root-tasks'].value,4);
 assert.equal(metrics['tracked-roots'].value,2);
 assert.equal(metrics['untracked-roots'].value,1);
 assert.deepEqual(metrics['creator-not-waiting'].siteIds,['c']);
 assert.deepEqual(metrics['cancellation-not-forwarded'].siteIds,['b']);
 assert.deepEqual(metrics['lifetime-unresolved'].siteIds,['d']);
});
