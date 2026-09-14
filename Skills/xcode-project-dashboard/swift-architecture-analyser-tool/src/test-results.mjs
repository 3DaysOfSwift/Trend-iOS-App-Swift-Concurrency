export function importTestResults(input) {
  for(const key of ['passedTests','failedTests','skippedTests','totalTestCount']) {
    if(!Number.isSafeInteger(input?.[key]) || input[key]<0) throw Error('Invalid Xcode test count: '+key);
  }
  if(input.passedTests+input.failedTests+input.skippedTests!==input.totalTestCount) throw Error('Xcode test counts do not sum to total');
  if(!Number.isFinite(input.startTime) || input.startTime<0) throw Error('Invalid Xcode test run timestamp');
  return {...Object.fromEntries(['passedTests','failedTests','skippedTests','totalTestCount','startTime'].map(k=>[k,input[k]])),sourceAlignment:'Not verified against this source scan'};
}
