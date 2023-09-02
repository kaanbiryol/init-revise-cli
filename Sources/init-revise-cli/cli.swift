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
        let extractor = ExpressionTypeExtractor(sourceFile: sourceFile, compilerArgs: compilerArgs)
        let expressions = try extractor.extract()
        
        let fileURL = URL(fileURLWithPath: sourceFile)
        let sourceCode = try String(contentsOf: fileURL, encoding: .utf8)
        let parsedSourceFile = Parser.parse(source: sourceCode)

        let newSourceCode = InitRewriter(expressionTypes: expressions.types).visit(parsedSourceFile)
        try newSourceCode.description.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
