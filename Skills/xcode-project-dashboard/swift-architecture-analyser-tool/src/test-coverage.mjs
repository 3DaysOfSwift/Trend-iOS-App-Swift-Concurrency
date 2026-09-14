// Import measured executable-line counts. Never average target percentages.
export function importTestCoverage(input, targetName) {
  if (!targetName || !Array.isArray(input?.targets)) throw new Error('Coverage requires xccov report JSON and --coverage-target.');
  const matches = input.targets.filter(t => t.name === targetName);
  if (matches.length !== 1) throw new Error('Coverage target must match exactly one target: '+targetName);
  const { coveredLines, executableLines } = matches[0];
  if (!Number.isSafeInteger(coveredLines) || !Number.isSafeInteger(executableLines) || coveredLines < 0 || executableLines < coveredLines)
    throw new Error('Invalid coverage line counts.');
  return { target: targetName, coveredLines, executableLines,
    value: executableLines ? Math.round(1000 * coveredLines / executableLines) / 10 : null,
    source: 'Imported Xcode test run', sourceAlignment: 'Not verified against this source scan' };
}
