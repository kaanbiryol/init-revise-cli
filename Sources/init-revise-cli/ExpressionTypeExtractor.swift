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
        return ExpressionTypeResponse(types: parseExpressionTypes(response))
    }

    private func parseExpressionTypes(_ response: [String: SourceKitRepresentable]) -> [ExpressionType] {
        let rawTypes: [[String: SourceKitRepresentable]]
        if let typedRawTypes = response["key.expression_type_list"] as? [[String: SourceKitRepresentable]] {
            rawTypes = typedRawTypes
        } else if let representableRawTypes = response["key.expression_type_list"] as? [SourceKitRepresentable] {
            rawTypes = representableRawTypes.compactMap { $0 as? [String: SourceKitRepresentable] }
        } else {
            return []
        }

        return rawTypes.compactMap { rawType in
            guard let length = rawType["key.expression_length"] as? Int64,
                  let offset = rawType["key.expression_offset"] as? Int64,
                  let type = rawType["key.expression_type"] as? String else {
                return nil
            }

            return ExpressionType(length: Int(length), offset: Int(offset), type: type)
        }
    }
}
