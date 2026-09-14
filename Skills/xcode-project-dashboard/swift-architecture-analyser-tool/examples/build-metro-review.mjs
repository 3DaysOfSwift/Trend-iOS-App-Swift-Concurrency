// Authored Metro review; generates evidence artifacts, never changes the app.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=path.resolve('../metro-mate-ios');
const inventory=JSON.parse(await fs.readFile('reports/metro-inventory/report.json','utf8'));
const out=path.resolve('reports/metro-review-inputs');
const files=new Map();
async function walk(dir){for(const item of await fs.readdir(dir,{withFileTypes:true})){if(item.name.startsWith('.'))continue;const p=path.join(dir,item.name);if(item.isDirectory())await walk(p);else if(p.endsWith('.swift'))files.set(path.relative(root,p),await fs.readFile(p,'utf8'));}}
await walk(path.join(root,'Metronome'));await walk(path.join(root,'MetronomeTests'));
function ref(name,needle,length=12){const paths=[...files.keys()].filter(p=>path.basename(p)===name);if(paths.length!==1)throw Error('Ambiguous file '+name);const file=paths[0],lines=files.get(file).split('\n');const line=typeof needle==='number'?needle:lines.findIndex(l=>l.includes(needle))+1;if(line<1)throw Error('Missing '+needle);return {file,line,endLine:Math.min(lines.length,line+length-1)};}
const manager='MetronomeManager.swift';
const rules=[
 ['Tempo validation and clamping',manager,'func updateBPM'],
 ['Note selection rebuilds the musical pattern',manager,'func updateNoteValue'],
 ['Beat-count limits and safe pattern edits',manager,'func updateBeatsPerMeasure'],
 ['Tap tempo uses recent intervals',manager,'func tapTempo'],
 ['Built-in musical preset definitions',manager,'private func makeDefaultPreset'],
 ['Saved preset input normalization',manager,'func loadBeatPreset'],
 ['Random rhythms preserve tempo and first-beat accent',manager,'func randomizeBeat'],
 ['Reset restores the basic beat',manager,'func resetToBasicBeat'],
 ['Start is shared and superseded starts cannot publish',manager,'func startPlayback()'],
 ['Stop invalidates playback and orders audio cleanup',manager,'private func stop()'],
 ['Preset edits preserve arrival order',manager,'private func applyPresetEdit'],
 ['Preset writes coalesce snapshots without dropping edits',manager,'private func persistPresets'],
 ['Load sharing and retry readiness',manager,'func loadSavedPresets'],
 ['Expired audio deadlines are skipped, not replayed','MetronomeBeatSchedule.swift','mutating func refill'],
 ['Committed audio deadlines survive pending tempo edits','MetronomeBeatSchedule.swift','mutating func update']
];
const decisions=rules.map(([description,file,needle],i)=>({id:'rule-'+i,description,location:'model',testable:true,evidence:[ref(file,needle)],testStatus:'unknown'}));
const journeys=[];
function journey(file,line,title,steps,unknowns=[]){const f=inventory.files.find(f=>path.basename(f.path)===file);const site=f.sites.find(s=>s.line===line&&['task','async-let','view-task'].includes(s.kind));if(!site)throw Error('Missing Task '+file+line);journeys.push({id:'journey-'+journeys.length,siteId:site.id,title,scope:'Source-derived lifecycle; not a runtime trace.',steps:steps.map(([action,task,context,f,n,len])=>({action,task,context,evidence:[ref(f,n,len??12)]})),unknowns});}
journey('App.swift',30,'Launch: two structured children',[
 ['SwiftUI creates the launch Task','Launch','SwiftUI lifecycle','App.swift',30,4],
 ['Create audio and preset child Tasks, then await both','Launch → audio child + preset child','MainActor orchestration','AppModel.swift',15,5],
 ['Audio child awaits an explicitly queued operation','Audio child awaits an unstructured operation','MainActor → audio actor',manager,'func prepareAudio',14],
 ['Preset child awaits the manager-owned shared load','Preset child awaits an unstructured load','MainActor → storage actor',manager,'func loadSavedPresets',26]
 ],['SwiftUI cancellation propagates to the two structured children, not automatically into the retained manager Tasks they await. Actual parallel execution was not measured.']);
journey(manager,538,'Save: ordered edit → coalesced persistence',[
 ['Capture the requested beat before suspension','Calling Task','MainActor',manager,'func saveBeatPreset',24],
 ['Create a retained edit Task and await the preceding edit','Preset edit Task','MainActor',manager,535,18],
 ['Await shared initial load, apply edit, submit snapshot','Preset edit Task','MainActor',manager,542,8],
 ['One retained worker drains the latest pending collection','Persistence Task','MainActor',manager,'private func persistPresets',31],
 ['Encode and persist synchronously on the storage actor executor','Persistence Task','Serial off-main storage executor','UserDefaultsPresetRepository.swift','func savePresets',7]
 ],['A successful UserDefaults.set is not proof of durable media flush. Caller cancellation intentionally does not discard submitted edits.']);
journey(manager,187,'Playback: shared start and ordered stop',[
 ['Repeated starts await the retained start Task','Start Task','MainActor',manager,'func startPlayback()',15],
 ['Await predecessor, start audio and schedule a pattern','Start Task awaits audio operation Task','MainActor → serial audio actor',manager,198,24],
 ['Check cancellation and revision before publishing playback','Start Task','MainActor',manager,219,12],
 ['Stop invalidates revisions, cancels workers and awaits queued cleanup','Stop caller','MainActor',manager,'private func stop()',28]
 ]);
journey('AVFoundationMetronomeAudioPlayer.swift',144,'Audio: bounded refill loop',[
 ['Retain one weak-owner refill Task after scheduling playback','Refill Task','Audio actor creates Task','AVFoundationMetronomeAudioPlayer.swift',138,20],
 ['Sleep, check cancellation, then validate playback generation','Refill Task','Await audio actor','AVFoundationMetronomeAudioPlayer.swift',188,8],
 ['Commit a bounded look-ahead window and schedule reusable voices','Refill Task','Serial audio executor','AVFoundationMetronomeAudioPlayer.swift',196,15],
 ['On failure stop playback and preserve an error for the feature','Refill Task','Audio actor','AVFoundationMetronomeAudioPlayer.swift',212,6]
 ],['Sleep timing and audio quality require device measurements. Actor-executor boundaries are source-derived, not profiler observations.']);
journey('SwiftConcurrencyMetronomeTicker.swift',13,'UI playhead polling: replace and cancel',[
 ['Cancel previous polling and retain the replacement','Polling Task','MainActor','SwiftConcurrencyMetronomeTicker.swift',6,26],
 ['Await playhead, then reject stale pattern or playback results','Polling Task','MainActor → audio actor',manager,'private func tick',29],
 ['Stop and destruction request cancellation','Owner','MainActor','SwiftConcurrencyMetronomeTicker.swift',35,9]
 ]);
journey('StarFieldViewModel.swift',86,'Animation: render off MainActor, publish current frame',[
 ['Only start one retained animation Task','Animation Task','MainActor','StarFieldViewModel.swift',84,18],
 ['Await rendering and reject a superseded canvas revision','Animation Task','MainActor → presentation actor','StarFieldViewModel.swift',95,14],
 ['Disappearance cancels the animation','ViewModel owner','MainActor','StarFieldViewModel.swift',45,4]
 ]);
const scenarios=[];
function tested(title,file,needle,detail,length=18){scenarios.push({title,status:'identified',detail,evidence:[ref(file,needle,length)]});}
tested('Input boundaries reject invalid tempo and indices','MetronomeManagerCharacterisationTests.swift','func featureCommandsProtectTheirOwnInputBoundaries','Assertions check clamping, non-finite input rejection and unchanged patterns.',27);
tested('Repeated starts share pending work','MetronomeAudioConcurrencyTests.swift','func repeatedRequestsShareThePendingStart','Suspends start, launches another request, then asserts one start and one ticker.',21);
tested('Stop during start prevents stale playback','MetronomeAudioConcurrencyTests.swift','func stopDuringStartPreventsLatePlayback','Asserts cancellation, ordered start/stop/start and final playback state.',31);
tested('Stop waits for an in-flight click','MetronomeAudioConcurrencyTests.swift','func stopWaitsForInFlightClick','Asserts command ordering and no resumed visual beat after stop.',25);
tested('Startup audio does not block preset loading','MetronomeAudioConcurrencyTests.swift','func startupLoadsPresetsWhileAudioPreparationIsSuspended','Both dependencies reach suspension before either is released.',17);
tested('Initial-load edits keep submission order','MetronomePresetPersistenceTests.swift','func sameNameEditsWaitingForInitialLoad','Checks final BPM, persisted latest snapshot and a single named preset.',36);
tested('Coalesced writes preserve edits despite caller cancellation','MetronomePresetPersistenceTests.swift','func slowStorageCoalescesSnapshotsWithoutLosingEdits','Checks two writes preserve three edits and clear saving state.',28);
tested('Concurrent callers share one load','MetronomePresetPersistenceTests.swift','func concurrentCallersShareOnePendingLoad','Asserts one repository load and loading state clears.',20);
tested('Save captures input before suspension','MetronomePresetPersistenceTests.swift','func saveCapturesTheBeatBeforeLoadingSuspends','Changes BPM during load and checks the captured original reaches storage.',15);
tested('Failed saves can retry without duplication','MetronomePresetPersistenceTests.swift','func failedSaveRetainsChangesForRetry','Asserts visible failure, retained local edits and successful retry.',14);
tested('Late audio refill skips expired beats','MetronomeBeatScheduleTests.swift','func delayedRefillSkipsExpiredBeats','Checks skipped count, absolute deadlines and musical indices.',9);
tested('Tempo changes preserve committed deadlines','MetronomeBeatScheduleTests.swift','func rapidEditsReplacePendingTempo','Checks exact absolute deadlines after several pending updates.',11);
for(const [title,file,needle,detail] of [
 ['Audio interruption and route recovery','AVFoundationMetronomeAudioPlayer.swift','func prepare','No interruption/route-change recovery test or notification handler found in the searched production/test scope. Agree intended resume/stop behaviour before writing tests.'],
 ['Live refill failure reaches visible feature state','AVFoundationMetronomeAudioPlayer.swift','private func failPlayback','Pure schedule tests cover deadlines, but a deterministic live refill-worker failure followed by feature error publication was not identified.'],
 ['Cancelling one caller leaves a shared preset load usable',manager,'func loadSavedPresets','Load sharing is tested, and save cancellation is tested. A focused cancelled-load-waiter scenario was not identified in MetronomeTests.']
 ])scenarios.push({title,status:'not-identified',detail,evidence:[ref(file,needle,18)]});
const findings=[
 {title:'How does playback recover from an audio interruption?',status:'Recovery policy requires review',description:'Preparation activates the audio session. No interruption or route-change observer was found. Define what the user should see when a call or audio-device change interrupts playback; this source review does not establish a reproduced failure.',check:'Exercise interruption, route change and media-services reset on device; assert the intended stop/resume and error behaviour.',evidence:[ref('AVFoundationMetronomeAudioPlayer.swift','func prepare',13)]},
 {title:'Should a failed preset decode erase the saved payload?',status:'Confirmed destructive recovery policy',description:'The storage actor removes the preset key after any JSON decoding failure. That includes data the current schema cannot decode. Decide whether preserving or quarantining the payload would better support recovery.',check:'Test an unsupported schema and corrupt payload, including what remains available after a second load.',evidence:[ref('UserDefaultsPresetRepository.swift','func loadPresets',13)]}
];
const scope='Focused review of 15 core rule groups and 15 concurrency/behaviour scenarios across playback, timing, presets and launch. Presentation-only gestures, visual styling and formatting are excluded from separation. Not an exhaustive whole-app certification; no tests or runtime tracing executed in this review.';
const observations={schemaVersion:1,sourceFingerprint:inventory.sourceFingerprint,author:'Xcode Project Dashboard · source review',createdAt:new Date().toISOString(),scope,journeys,separation:{complete:false,ratingScope:'reviewed-rules',hasTestableModel:true,rationale:'All 15 reviewed product-rule groups have testable Model implementations. UI gesture sensitivity, screen state and visual effects are presentation, not musical rules. This is a scoped assessment, not proof that every rule was found.',decisions}};
const review={schemaVersion:1,sourceFingerprint:inventory.sourceFingerprint,author:'Xcode Project Dashboard · source review',scope,findings,testQuality:{scope,scenarios,concerns:[],keep:{title:'Observation tests are not merely stored-property readbacks',detail:'The save-dialog test also checks observation invalidation and that draft editing leaves persisted feature state untouched. Those assertions protect a presentation contract; it should not be dismissed solely because a property is assigned.',evidence:[ref('BeatPresetsViewModelTests.swift','func saveDialogBindingsUpdateOnlyLocalPresentationState',15)]}},evidenceHashes:Object.fromEntries([...files].filter(([p])=>p.startsWith('MetronomeTests/')).map(([p,s])=>[p,createHash('sha256').update(s).digest('hex')]))};
await fs.mkdir(out);for(const [name,data] of [['observations',observations],['review',review]])await fs.writeFile(path.join(out,name+'.json'),JSON.stringify(data,null,2),{flag:'wx'});
console.log({out,rules:decisions.length,matched:12,scenarios:scenarios.length,journeys:journeys.length});
