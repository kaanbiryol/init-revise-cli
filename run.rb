#!/usr/bin/env ruby
require 'json'
require 'xcodeproj'

$workspacePath = File.expand_path(ARGV[0])
$projectPath = File.expand_path(ARGV[1])

$xcodeproj = Xcodeproj::Project.open($projectPath)
$allTargets = $xcodeproj.targets

$workspace = Xcodeproj::Workspace.new_from_xcworkspace($workspacePath)
$allSchemes = $workspace.schemes.to_a

$allTargetsBuildSettingsJSON = JSON.parse(`xcodebuild -project #{$projectPath} -alltargets -arch arm64 -sdk iphonesimulator -showBuildSettingsForIndex -json`)

def getKey(json)
    if json.is_a?(Hash)
        return json.keys
    else
        return []
    end
end

def revise(targetFiles, targetBuildSettings, compilerArgs)
    for file in targetFiles do
        if !targetBuildSettings[file]["swiftASTCommandArguments"].nil?
            compilerArgs += targetBuildSettings[file]["swiftASTCommandArguments"]
        end
        if compilerArgs.empty?
            next
        end
        args = compilerArgs.join(" ")
        puts "Revising #{file}"
        `./init-revise-cli #{file} -- #{args}`
    end
end

def findTargetDependencies(target_name)
    target = $xcodeproj.targets.find { |t| t.name == target_name }
    return [] unless target
    dependencies = target.dependencies.map do |dependency|
        dependency.target.name
    end
    return dependencies
end

def getDependencyCompilerArgs(target) 
    compilerArgs = []
    dependencies = findTargetDependencies(target.name)
    for dependency in dependencies do
        dependencyTargetName = $allTargets.find { |target| target.name == dependency }.name
        dependencyBuildSettings = $allTargetsBuildSettingsJSON[dependencyTargetName]
        dependencyFiles = getKey(dependencyBuildSettings)
        for dependencyFile in dependencyFiles do
            if !dependencyBuildSettings[dependencyFile]["swiftASTCommandArguments"].nil?
                compilerArgs += dependencyBuildSettings[dependencyFile]["swiftASTCommandArguments"]
            end
        end
    end
    return compilerArgs
end

def reviseTargets(targets)
    for target in targets do 
        targetBuildSettings = $allTargetsBuildSettingsJSON[target.name]
        targetFiles = getKey(targetBuildSettings)
        compilerArgs = getDependencyCompilerArgs(target)
        revise(targetFiles, targetBuildSettings, compilerArgs)
    end
end

def reviseSchemes(schemes)
    for target in schemes
        schemeBuildSettings = JSON.parse(`xcodebuild -workspace #{$workspacePath} -scheme #{target.name} -arch arm64 -sdk iphonesimulator -showBuildSettingsForIndex -json`)
        targetBuildSettings = schemeBuildSettings[target.name]
        targetFiles = getKey(targetBuildSettings)
        compilerArgs = getDependencyCompilerArgs(target)
        revise(targetFiles, targetBuildSettings, compilerArgs)
    end
end

def separateSchemesAndTargets()
    schemes = []
    targets = []
    
    $allTargets.each do |target|
        if $allSchemes.any? { |scheme| target.name == scheme[0] }
            schemes << target
        else
            targets << target
        end
    end
    return [schemes, targets]
end

schemesAndTargets = separateSchemesAndTargets()
reviseSchemes(schemesAndTargets[0])
reviseTargets(schemesAndTargets[1])