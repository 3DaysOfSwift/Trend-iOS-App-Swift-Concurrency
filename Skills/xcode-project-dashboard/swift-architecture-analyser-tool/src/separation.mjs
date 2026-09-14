// A reviewed decision inventory, not a count of conditionals or test files.
export function separation(review) {
  if (!review?.complete && review?.ratingScope !== 'reviewed-rules') return {value:null,reason:'Business-decision review not complete'};
  if (!review.hasTestableModel) return {value:0,reason:'No meaningful testable model boundary'};
  if (!review.decisions.length) return {value:null,reason:'No business decisions classified'};
  const isolated=review.decisions.filter(d=>d.location==='model' && d.testable).length;
  const partial=!review.complete;
  return {value:Math.round(100*isolated/review.decisions.length),partial,reason:isolated+' of '+review.decisions.length+' reviewed business-rule groups isolated in a testable model'+(partial?'. Reviewed rules only—not an exhaustive whole-app measurement.':'')};
}
