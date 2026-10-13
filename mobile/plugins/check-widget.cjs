const assert = require('node:assert/strict');
const path = require('node:path');
const xcode = require('xcode');
const { configureProject } = require('./withDriftWidget.cjs');

const project = xcode.project(path.join(__dirname, '../ios/Drift.xcodeproj/project.pbxproj'));
project.parseSync();
const config = { ios: { bundleIdentifier: 'com.bipinrimal.drift.mobile' }, version: '1.0.0' };
configureProject(project, config);
const first = project.writeSync();
configureProject(project, config);
assert.equal(project.writeSync(), first, 'Repeated prebuild must not add project objects');
const objects = project.hash.project.objects;
const targets = Object.entries(objects.PBXNativeTarget).filter(([id, target]) =>
  !id.endsWith('_comment') && target.name.replaceAll('"', '') === 'DriftWidget');
assert.equal(targets.length, 1);
const [id, widget] = targets[0];
assert.equal(widget.productType, '"com.apple.product-type.app-extension"');
const sources = widget.buildPhases.map(phase => objects.PBXSourcesBuildPhase[phase.value]).find(Boolean);
assert.equal(sources.files.length, 2);
assert.equal(project.getFirstTarget().firstTarget.dependencies.filter(reference =>
  objects.PBXTargetDependency[reference.value]?.target === id).length, 1);
const embedded = project.getFirstTarget().firstTarget.buildPhases
  .map(phase => objects.PBXCopyFilesBuildPhase[phase.value]).filter(Boolean)
  .flatMap(phase => phase.files).filter(reference =>
    objects.PBXBuildFile[reference.value].fileRef === widget.productReference);
assert.equal(embedded.length, 1);
assert(!first.includes('undefined'));
console.log('iOS widget source membership, embedding, dependency, and repeated prebuild checks passed');
