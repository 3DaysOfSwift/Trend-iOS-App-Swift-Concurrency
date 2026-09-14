#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import { analyse } from './analyse.mjs';
import { render } from './render.mjs';
import { importTestCoverage } from './test-coverage.mjs';
import { attachObservations, readObservationEvidence } from './observations.mjs';
import {importTestResults} from './test-results.mjs';
import {importReview} from './review-import.mjs';

const args = process.argv.slice(2);
if (!args.length || args.includes('--help')) {
  console.log('Usage: node src/cli.mjs <repository> --out <new-report-directory> [--project-name <name>] [--include-tests] [--observations <json-file>] [--review <json-file>] [--test-results <xcresult-summary-json>] [--coverage <xccov-json> --coverage-target <exact-target-name>]\nReads Swift source locally. Imports evidence-backed ratings and Xcode results. Writes report.html and report.json. Does not edit the repository.');
} else {
  try {
    const repository = args.shift();
    let output, observations, coverage, coverageTarget, review, testResults, projectName, includeTests = false;
    while (args.length) {
      const flag = args.shift();
      if (flag === '--out' && args[0] && !args[0].startsWith('--')) output = args.shift();
      else if (flag === '--observations' && args[0] && !args[0].startsWith('--')) observations = args.shift();
      else if (flag === '--include-tests') includeTests = true;
      else if (flag === '--coverage' && args[0] && !args[0].startsWith('--')) coverage = args.shift();
      else if (flag === '--coverage-target' && args[0] && !args[0].startsWith('--')) coverageTarget = args.shift();
      else if (flag === '--review' && args[0] && !args[0].startsWith('--')) review = args.shift();
      else if (flag === '--test-results' && args[0] && !args[0].startsWith('--')) testResults = args.shift();
      else if (flag === '--project-name' && args[0] && !args[0].startsWith('--')) projectName = args.shift();
      else throw new Error(`Unknown or incomplete option: ${flag}`);
    }
    if (!output) throw new Error('--out must name a new report directory; existing output is never overwritten.');
    output = path.resolve(output);
    try { await fs.lstat(output); throw new Error('Output already exists. Choose a new report directory.'); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    let report = await analyse(repository, { includeTests, excludedOutput: output });
    if(!report.files.some(f=>f.usesSwiftConcurrency)) throw Error('No Swift Concurrency syntax found in the selected scope. This dashboard requires a Swift Concurrency project; verify target scope or use a legacy migration review.');
    if(projectName) report.project=projectName;
    if(testResults) report.testRun=importTestResults(JSON.parse(await fs.readFile(testResults,'utf8')));
    if(review) report.reviewData=await importReview(report,JSON.parse(await fs.readFile(review,'utf8')),repository);
    if (!!coverage !== !!coverageTarget) throw new Error('Use --coverage and --coverage-target together.');
    if (coverage) report.testCoverage = importTestCoverage(JSON.parse(await fs.readFile(coverage, 'utf8')), coverageTarget);
    if (observations) {
      report = attachObservations(report, JSON.parse(await fs.readFile(observations, 'utf8')));
      await readObservationEvidence(report, repository);
    }
    if (!report.scope.fileCount) throw new Error('No Swift files found in the selected scope.');
    await fs.mkdir(output, { recursive: true });
    await fs.writeFile(path.join(output, 'report.json'), JSON.stringify(report, null, 2) + '\n', { flag: 'wx' });
    await fs.writeFile(path.join(output, 'report.html'), render(report), { flag: 'wx' });
    console.log(`Analysed ${report.scope.fileCount} Swift files.\nOpen: ${path.join(output, 'report.html')}\nReport contains source excerpts; review before sharing.`);
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
