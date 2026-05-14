import ArgumentParser
import SwiftSyntax
import SwiftParser
import Foundation
import SourceKittenFramework

@main
struct cli: ParsableCommand {
    @Argument
    var sourceFile: String
    
    @Argument
    var compilerArgs: [String] = []

    mutating func run() throws {
        let fileURL = URL(fileURLWithPath: sourceFile)
        let sourceCode = try String(contentsOf: fileURL, encoding: .utf8)
        guard sourceCode.containsInitCandidate else { return }

        let extractor = ExpressionTypeExtractor(sourceFile: sourceFile, compilerArgs: compilerArgs)
        let expressions = try extractor.extract()
        guard !expressions.types.isEmpty else { return }

        let parsedSourceFile = Parser.parse(source: sourceCode)

        let newSourceCode = InitRewriter(expressionTypes: expressions.types).visit(parsedSourceFile).description
        guard newSourceCode != sourceCode else { return }

        try newSourceCode.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

private extension String {
    var containsInitCandidate: Bool {
        range(of: #"\.\s*init\s*\("#, options: .regularExpression) != nil
    }
}
