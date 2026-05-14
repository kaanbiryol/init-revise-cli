#!/usr/bin/env ruby
require 'json'
require 'open3'
require 'xcodeproj'

$workspacePath = File.expand_path(ARGV[0])
$projectPath = File.expand_path(ARGV[1])

$xcodeproj = Xcodeproj::Project.open($projectPath)
$allTargets = $xcodeproj.targets

$workspace = Xcodeproj::Workspace.new_from_xcworkspace($workspacePath)
$allSchemes = $workspace.schemes.to_a

$dependencyCompilerArgsCache = {}

def xcodebuildJSON(*args)
    output, status = Open3.capture2("xcodebuild", *args)
    raise "xcodebuild failed: #{args.join(" ")}" unless status.success?

    JSON.parse(output)
end

$allTargetsBuildSettingsJSON = xcodebuildJSON("-project", $projectPath, "-alltargets", "-arch", "arm64", "-sdk", "iphonesimulator", "-showBuildSettingsForIndex", "-json")

def getKey(json)
    if json.is_a?(Hash)
        return json.keys
    else
        return []
    end
end

def initCandidate?(file)
    File.file?(file) && File.read(file).match?(/\.\s*init\s*\(/)
rescue Errno::ENOENT, Errno::EACCES
    false
end

def revise(targetFiles, targetBuildSettings, dependencyCompilerArgs)
    for file in targetFiles do
        fileCompilerArgs = targetBuildSettings[file]["swiftASTCommandArguments"]
        next if fileCompilerArgs.nil? || fileCompilerArgs.empty?
        next unless initCandidate?(file)

        compilerArgs = dependencyCompilerArgs + fileCompilerArgs
        if compilerArgs.empty?
            next
        end
        puts "Revising #{file}"
        raise "init-revise-cli failed for #{file}" unless system("./init-revise-cli", file, "--", *compilerArgs)
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
    cachedCompilerArgs = $dependencyCompilerArgsCache[target.name]
    return cachedCompilerArgs unless cachedCompilerArgs.nil?

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
    $dependencyCompilerArgsCache[target.name] = compilerArgs
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
        schemeBuildSettings = xcodebuildJSON("-workspace", $workspacePath, "-scheme", target.name, "-arch", "arm64", "-sdk", "iphonesimulator", "-showBuildSettingsForIndex", "-json")
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
