build:
	swift build --configuration release --arch arm64 && mv .build/arm64-apple-macosx/release/init-revise-cli .

test:
	./run.rb Example/Example.xcworkspace "Example Example-Workspace ExampleKit" --silent
