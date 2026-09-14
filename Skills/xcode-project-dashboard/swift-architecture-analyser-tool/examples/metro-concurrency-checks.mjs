// Focused authored review. This is not the reusable scanner or a full Metro audit.
import fs from 'node:fs/promises';
import path from 'node:path';
import {analyse} from '../src/analyse.mjs';
const root=path.resolve('../metro-mate-ios');
const inventory=await analyse(root);
const review=JSON.parse(await fs.readFile('reports/metro-lifetime-inputs/review.json','utf8'));
if(review.sourceFingerprint!==inventory.sourceFingerprint) throw Error('Metro changed; re-review the evidence.');
review.scope='Focused review of preset loading and saving: navigation, repeated requests and live storage. Full architecture analysis remains incomplete; project ratings withheld.';
const file=name=>{const matches=inventory.files.filter(f=>path.basename(f.path)===name);if(matches.length!==1)throw Error('Ambiguous source '+name);return matches[0]};
const ref=(name,line,endLine)=>({file:file(name).path,line,endLine});
const entry=(line)=>{const s=file('BeatPresetsView.swift').sites.find(s=>s.line===line&&['task','view-task'].includes(s.kind));if(!s)throw Error('Trigger changed');return s.id};
const wiring=[ref('AppModel.swift',22,41)];
review.concurrencyChecks=[{
  siteId:entry(106),title:'Does leaving Presets cancel the shared load?',status:'managed',
  path:'BeatPresetsView .task → BeatPresetsViewModel.loadSavedPresets → MetronomeManager.loadSavedPresets → UserDefaultsPresetRepository.loadPresets',
  trigger:'SwiftUI starts the View task; this modifier has no changing ID.',
  navigation:'SwiftUI requests cancellation of the View task when its lifetime ends. The manager-owned load is independent and is not cancelled by that request.',
  repetition:'Requests join presetLoadTask while loading; successful loads return immediately on later calls. Failure remains visible and permits retry.',
  lifetime:'The caller awaits the retained load. No cancellation forwarding is intentional: startup and this screen share the same manager. Waiting may therefore continue after the View task is cancelled.',
  effect:'Live storage is local UserDefaults, not a server. Reading can delete the stored key if decoding fails, then throw; the manager publishes the error. This recovery side effect also survives navigation and deserves a separate data-recovery review.',
  conclusion:'The shared-load lifetime is explicitly managed; navigation does not interrupt this worker. This does not endorse the destructive decode-recovery policy.',
  verification:'Source inspection only in this update. Regression scenario: suspend repository loading, cancel one of two callers, complete loading and verify the other caller receives the result.',
  evidence:[ref('BeatPresetsView.swift',106,106),ref('BeatPresetsViewModel.swift',17,18),ref('BeatPresetsViewModel.swift',32,34),...wiring,ref('MetronomeManager.swift',593,617),ref('UserDefaultsPresetRepository.swift',23,32)]
},{
  siteId:entry(133),title:'Can navigation or repeated Save requests interrupt persistence?',status:'managed',
  path:'Save Button Task → BeatPresetsViewModel.saveCurrentBeat → MetronomeManager.saveBeatPreset → applyPresetEdit → persistPresets → UserDefaultsPresetRepository.savePresets',
  trigger:'The alert Save action creates a Task. It is not the View .task modifier.',
  navigation:'There is no View-lifetime cancellation for this Button Task. The shared model retains edit and save workers, so dismissing the screen does not request their cancellation.',
  repetition:'Two invocations do not cancel one another. Each captures its preset before awaiting; edit Tasks await their predecessor. Same-name presets replace existing entries. One save worker writes snapshots sequentially and coalesces pending snapshots to the latest collection.',
  lifetime:'Button handle is not stored here; manager edit/save handles are retained and joined. MainActor serialization covers submission before the first await; the explicit chain, not actor isolation alone, orders whole edits.',
  effect:'UserDefaults receives encoded data locally; no server request occurs. Save failures are published in presetSaveError and retry submits the collection without reapplying an edit. UserDefaults.set returning is not a guarantee of a disk flush or survival of process termination.',
  conclusion:'The reviewed save path has explicit ordering and persistence ownership. Extra invocations may create bridge Tasks, but they do not cancel an earlier save or launch concurrent repository writes.',
  verification:'Source inspection only in this update. Regression scenario: hold the first repository write, submit another same-name save, navigate away, release storage and verify the latest collection and error/retry state.',
  evidence:[ref('BeatPresetsView.swift',129,135),ref('BeatPresetsViewModel.swift',42,45),...wiring,ref('MetronomeManager.swift',512,550),ref('MetronomeManager.swift',556,591),ref('UserDefaultsPresetRepository.swift',35,39)]
}];
await fs.mkdir('reports/metro-concurrency-inputs',{recursive:true});
await fs.writeFile('reports/metro-concurrency-inputs/review.json',JSON.stringify(review,null,2),{flag:'wx'});
