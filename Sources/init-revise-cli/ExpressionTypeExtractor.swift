import Foundation
import SourceKittenFramework

final class ExpressionTypeExtractor {
    
    private let sourceFile: String
    private let compilerArgs: [String]

    init(sourceFile: String, compilerArgs: [String]) {
        self.sourceFile = sourceFile
        self.compilerArgs = compilerArgs
    }

    func extract() throws -> ExpressionTypeResponse  {
        let yaml = expressionRequest(sourceFile: sourceFile, compilerArgs: compilerArgs)
        let request = SourceKittenFramework.Request.yamlRequest(yaml: yaml)
        let response = try request.send()
        let data = toJSON(toNSDictionary(response)).data(using: .utf8)!
        let expression = try JSONDecoder().decode(ExpressionTypeResponse.self, from: data)
        return expression
    }
}
