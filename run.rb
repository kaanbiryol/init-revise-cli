#!/usr/bin/env ruby
require 'json'
require 'open3'

$workspacePath = ARGV[0]
$schemes = ARGV[1]
$silent = false

ARGV.each do |arg|
    case arg
    when '--silent'
        $silent = true
    end
end

def listSchemes(workspacePath)
    `xcodebuild -list -workspace #{workspacePath}`
end

# -destination 'platform=iOS Simulator,name=iPhone 14 Pro,OS=16.4'
def buildSettingsForIndex(workspacePath, scheme)
    stdout, stderr, status = Open3.capture3("xcodebuild -workspace #{workspacePath} -scheme #{scheme} -showBuildSettings -showdestinations -showBuildSettingsForIndex -verbose")
    if !$silent 
        puts stdout
    end
    return stdout
end

def rewrite(file, scheme, rawBuildSettings)
    ## Remove extra information from the output
    extractedBuildSettings = rawBuildSettings.match(/Build settings for target #{scheme}:(.*)/m)[1].strip
    buildSettings = JSON.parse(extractedBuildSettings)
    compilerArgs = buildSettings[file]["swiftASTCommandArguments"]
    # compilerArgs = astArguments.drop(4) #drop -modulename "ModuleName" arguments
    compilerArgs = compilerArgs.join(" ")
    puts "Revising #{file} in #{scheme}"
    stdout, stderr, status = Open3.capture3("./init-revise-cli #{file} -- #{compilerArgs}")
    if !$silent 
        puts stdout
    end
end

def findSchemeDirectory(directory_path, folder_name)
    matching_folders = []
    Dir.glob(File.join(directory_path, '**', folder_name)).each do |folder|
        if File.directory?(folder)
            matching_folders << folder
        end
    end
    matching_folders
end

def findSwiftFiles(directory_path)
    swift_files = []
    Dir.glob(File.join(directory_path, '**', '*.swift')).each do |swift_file|
        swift_files << swift_file
    end
    swift_files
end

schemes = $schemes.split(" ")

for scheme in schemes do
    rawBuildSettings = buildSettingsForIndex($workspacePath, scheme)
    schemeDirectory = findSchemeDirectory(Dir.pwd, scheme)
    files = findSwiftFiles(Dir.pwd)
    for file in files do
        begin
            rewrite(file, scheme, rawBuildSettings)
        rescue
        end
    end
end