.PHONY: bundle build test

bundle:
	bundle install

build: bundle
	swift build --configuration release --arch arm64 && mv .build/arm64-apple-macosx/release/init-revise-cli .

test: bundle
	bundle exec ./run.rb "Example/Example.xcworkspace" "Example/Example.xcodeproj"
