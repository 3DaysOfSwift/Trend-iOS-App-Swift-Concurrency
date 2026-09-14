import test from 'node:test';
import assert from 'node:assert/strict';
import { importTestCoverage } from '../src/test-coverage.mjs';
test('coverage uses measured counts for one explicit target, never averaged percentages',()=>{
  const input={targets:[{name:'App',coveredLines:3,executableLines:8,lineCoverage:1},{name:'Tests',coveredLines:100,executableLines:100}]};
  assert.equal(importTestCoverage(input,'App').value,37.5);
  assert.throws(()=>importTestCoverage(input,'Missing'));
  assert.throws(()=>importTestCoverage(input));
  assert.throws(()=>importTestCoverage({targets:[{name:'App',coveredLines:9,executableLines:8}]},'App'));
  assert.equal(importTestCoverage({targets:[{name:'App',coveredLines:0,executableLines:0}]},'App').value,null);
  assert.equal(importTestCoverage({targets:[{name:'App',coveredLines:0,executableLines:8}]},'App').value,0);
});
