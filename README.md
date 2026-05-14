# init-revise-cli

A Swift CLI that rewrites `.init(...)` calls to explicit type initializers using SourceKit type resolution - reducing Swift type-checker overhead in large codebases.

```swift
// before
doSomething(model: .init(value: "1"))

// after
doSomething(model: Test.ViewModel(value: "1"))
```

## Why?

Implicit `.init(...)` forces the Swift type checker to infer types from context. In complex expressions with generics or deeply nested calls, this can **increase build times**. (not always!)

Replacing `.init(...)` with explicit types gives the compiler a direct resolution path.

## What it does

- Queries SourceKit for resolved expression types using your project's compiler arguments
- Parses Swift source files into an AST via [swift-syntax](https://github.com/swiftlang/swift-syntax)
- Replaces `.init(...)` tokens with fully-qualified type names
- Handles optionals, arrays, and nested types
- Rewrites files in place (atomic writes)

## Requirements

- Ruby with Bundler (`bundle`)

## Quick start

```sh
make build
./init-revise-cli <source-file> -- <compiler-args...>
```

## Usage

### Single file

```sh
./init-revise-cli MyFile.swift -- <compiler-args...>
```

Compiler args are the same flags passed to `swiftc`. Extract them from Xcode:

```sh
xcodebuild -project MyApp.xcodeproj -alltargets -arch arm64 \
  -sdk iphonesimulator -showBuildSettingsForIndex -json
```

Look for `swiftASTCommandArguments` in the JSON output.

### Batch mode (Xcode project)

`run.rb` processes all Swift files across targets and schemes, resolving per-file compiler arguments automatically:

```sh
bundle exec ./run.rb <workspace-path> <project-path>
```

> Defaults to `arm64` / `iphonesimulator`. Edit `run.rb` for other configurations.

### Example project

The repo includes an `Example/` Xcode project with `.init(...)` patterns across basic, optional, array, and nested cases.

The example project requires Tuist. Run `mise install` in `Example/` to install the pinned Tuist version, or install Tuist separately before running `tuist generate`.

```sh
cd Example && mise install && tuist generate && cd ..
make build
make test
```

Check `Example/Targets/ExampleKit/Sources/ExampleKit.swift` for the output. Reset with `git checkout -- Example/`.

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

## How it works

1. **Type extraction** - sends a SourceKit request with the file path and compiler args to resolve expression types at each byte offset
2. **AST rewriting** - walks the syntax tree via `SyntaxRewriter`, matches `.init(` tokens to their resolved types, and replaces them in place
3. **File output** - writes the transformed source back atomically (UTF-8)

## Additional sources

- [Why does adding a type name here speed up typechecking so much?](https://forums.swift.org/t/why-does-adding-a-type-name-here-speed-up-typechecking-so-much/66240)
- [Surprising compilation performance of nested .init() vs Constructable()](https://forums.swift.org/t/surprising-compilation-performance-of-nested-init-vs-constructable/69052)

## Limitations

- Requires **correct compiler arguments** - without them, SourceKit cannot resolve types
- **In-place only** - no dry-run mode; use version control
- Only targets `.init()` syntax (prefix-dot form) - does not transform `Self.init()` or already-explicit initializers
- Silently skips expressions where SourceKit cannot determine the type
