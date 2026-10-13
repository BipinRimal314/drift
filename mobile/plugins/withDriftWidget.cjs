const fs = require('node:fs');
const path = require('node:path');
const { withDangerousMod, withXcodeProject } = require('expo/config-plugins');

const name = 'DriftWidget';
const sourceFiles = ['DriftClock.swift', 'DriftWidget.swift'];

function configureProject(project, config) {
  const objects = project.hash.project.objects;
  objects.PBXTargetDependency ||= {};
  objects.PBXContainerItemProxy ||= {};
  let targetId = Object.keys(objects.PBXNativeTarget).find(id =>
    !id.endsWith('_comment') && objects.PBXNativeTarget[id].name.replaceAll('"', '') === name);
  if (!targetId) {
    targetId = project.addTarget(name, 'app_extension', name, `${config.ios.bundleIdentifier}.widget`).uuid;
  }
  const target = objects.PBXNativeTarget[targetId];
  const appTarget = project.getFirstTarget();
  if (!appTarget.firstTarget.dependencies.some(reference => objects.PBXTargetDependency[reference.value]?.target === targetId)) {
    project.addTargetDependency(appTarget.uuid, [targetId]);
  }
  for (const [type, label] of [['PBXSourcesBuildPhase', 'Sources'], ['PBXFrameworksBuildPhase', 'Frameworks'], ['PBXResourcesBuildPhase', 'Resources']]) {
    if (!target.buildPhases.some(phase => objects[type]?.[phase.value])) {
      project.addBuildPhase([], type, label, targetId);
    }
  }
  let groupId = project.findPBXGroupKey({ name });
  if (!groupId) {
    groupId = project.addPbxGroup([], name).uuid;
    delete objects.PBXGroup[groupId].path;
    project.addToPbxGroup(groupId, project.getFirstProject().firstProject.mainGroup);
  }
  for (const source of sourceFiles) {
    project.addSourceFile(`${name}/${source}`, { target: targetId }, groupId);
  }
  project.addFile(`${name}/${name}-Info.plist`, groupId);
  for (const reference of [...objects.PBXGroup[groupId].children, { value: target.productReference }]) {
    const file = objects.PBXFileReference[reference.value];
    for (const property of Object.keys(file)) {
      if (file[property] === undefined) delete file[property];
    }
  }
  const configurations = objects.XCConfigurationList[target.buildConfigurationList].buildConfigurations;
  for (const reference of configurations) {
    Object.assign(objects.XCBuildConfiguration[reference.value].buildSettings, {
      INFOPLIST_FILE: `"${name}/${name}-Info.plist"`,
      PRODUCT_BUNDLE_IDENTIFIER: `"${config.ios.bundleIdentifier}.widget"`,
      IPHONEOS_DEPLOYMENT_TARGET: '17.0',
      SWIFT_VERSION: '5.0',
      TARGETED_DEVICE_FAMILY: '"1,2"',
      APPLICATION_EXTENSION_API_ONLY: 'YES',
      CODE_SIGN_STYLE: 'Automatic',
      MARKETING_VERSION: config.version || '1.0.0',
      CURRENT_PROJECT_VERSION: String(config.ios.buildNumber || '1'),
      GENERATE_INFOPLIST_FILE: 'NO',
      SKIP_INSTALL: 'YES',
    });
  }
  project.addTargetAttribute('ProvisioningStyle', 'Automatic', { uuid: targetId });
  return project;
}

function withDriftWidget(config) {
  config = withDangerousMod(config, ['ios', async mod => {
    const source = path.join(mod.modRequest.projectRoot, 'native/ios-widget');
    const destination = path.join(mod.modRequest.platformProjectRoot, name);
    fs.mkdirSync(destination, { recursive: true });
    for (const file of [...sourceFiles, `${name}-Info.plist`]) {
      fs.copyFileSync(path.join(source, file), path.join(destination, file));
    }
    return mod;
  }]);
  return withXcodeProject(config, mod => {
    configureProject(mod.modResults, mod);
    return mod;
  });
}

module.exports = withDriftWidget;
module.exports.configureProject = configureProject;
