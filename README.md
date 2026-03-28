# init-revise-cli

A Swift CLI tool that replaces type-inferred `.init(...)` calls with explicit type initializations using SourceKit type information.

```swift
// before
doSomething(model: .init(value: "1"))

// after
doSomething(model: Test.ViewModel(value: "1"))
```

Handles optionals, arrays, and nested types.

## Why?

Using `.init(...)` instead of explicit type names can significantly slow down the Swift type checker, especially in complex expressions with generics or nested calls. Related Swift Forums discussions:

- [Why does adding a type name here speed up typechecking so much?](https://forums.swift.org/t/why-does-adding-a-type-name-here-speed-up-typechecking-so-much/66240)
- [Surprising compilation performance of nested .init() vs Constructable()](https://forums.swift.org/t/surprising-compilation-performance-of-nested-init-vs-constructable/69052)

## Requirements

- macOS 13+
- Xcode (default toolchain)
- Ruby with the `xcodeproj` gem (for `run.rb`)

## Build

```sh
make build
```

Produces the `init-revise-cli` binary in the project root.

## Usage

### Single file

```sh
./init-revise-cli <source-file> -- <compiler-args...>
```

The tool rewrites the file in place.

The compiler args are the same flags passed to `swiftc` when building the file. You can get them from Xcode's build settings:

```sh
xcodebuild -project MyApp.xcodeproj -alltargets -arch arm64 -sdk iphonesimulator -showBuildSettingsForIndex -json
```

Look for the `swiftASTCommandArguments` key in the JSON output for each file.

### Xcode project (batch)

`run.rb` processes all Swift files across targets and schemes in an Xcode project:

```sh
./run.rb <workspace-path> <project-path>
```

It resolves per-file compiler arguments and target dependencies automatically.

Edit `run.rb` if your project structure differs from the defaults (arm64, iphonesimulator).

## Example

The repo includes an `Example/` Xcode project with two targets:

- **Example** - an iOS app target
- **ExampleKit** - a framework target with `.init(...)` calls in `ExampleKit.swift` covering basic, optional, array, and nested patterns

### Prerequisites

- Xcode (full installation, not just Command Line Tools)
- `xcodeproj` Ruby gem: `gem install xcodeproj`
- [mise](https://mise.jdx.dev/) and [Tuist](https://tuist.io/) for generating the Xcode project

### Running

```sh
cd Example && mise install && tuist generate && cd ..
make build
make test
```

This runs the tool against all Swift files in the Example project. Check `Example/Targets/ExampleKit/Sources/ExampleKit.swift` for the results.

### Expected output

Before:

```swift
doSomething(model: .init(value: "1"))
doSomethingOptional(model: .init(value: "2"))
doSomethingArray(model: [
    .init(value: "3"),
    .init(value: "4"),
    .init(value: "5")
])
```

After:

```swift
doSomething(model: Test.ViewModel(value: "1"))
doSomethingOptional(model: Test.ViewModel(value: "2"))
doSomethingArray(model: [
    Test.ViewModel(value: "3"),
    Test.ViewModel(value: "4"),
    Test.ViewModel(value: "5")
])
```

### Reset

To restore the example files after running:

```sh
git checkout -- Example/
```
