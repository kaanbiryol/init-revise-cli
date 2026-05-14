import SwiftSyntax

final class InitRewriter: SyntaxRewriter {
    private let expressionTypesByOffset: [Int: ExpressionType]
    private var shouldRemoveNextToken = false
    
    init(expressionTypes: [ExpressionType]) {
        self.expressionTypesByOffset = expressionTypes.reduce(into: [:]) { result, expressionType in
            if result[expressionType.offset] == nil {
                result[expressionType.offset] = expressionType
            }
        }
    }
    
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard !shouldRemoveNextToken else {
            shouldRemoveNextToken = false
            return remove(token: token)
        }

        guard token.tokenKind == .prefixPeriod else { return token }
        guard let initToken = token.nextToken, initToken.tokenKind == .initKeyword else { return token }
        guard let leftParenToken = initToken.nextToken, leftParenToken.tokenKind == .leftParen else { return token }

        let offset = token.byteRange.endOffset - 1
        guard let actualExpressionType = expressionTypesByOffset[offset] else { return token }

        shouldRemoveNextToken = true
        let formattedType = formatExpressionType(type: actualExpressionType.type)
        let newToken = token.withKind(.identifier(formattedType))
        return newToken
    }
    
    private func formatExpressionType(type: String) -> String {
        // convert array literal to actual type
        if type.contains("ArrayLiteralElement") {
            if let startIndex = type.firstIndex(of: "<"),
               let endIndex = type.firstIndex(of: ">") {
                let start = type.index(after: startIndex)
                let extractedSubstring = type[start..<endIndex]
                return stripOptionalIfNeeded(type: String(extractedSubstring))
            }
        }
        return stripOptionalIfNeeded(type: type)
    }
    
    // there is no optional initialization
    private func stripOptionalIfNeeded(type: String) -> String {
        guard type.last == "?" else { return type }
        return String(type.dropLast())
    }
    
    private func remove(token: TokenSyntax) -> TokenSyntax {
        return token.withKind(.identifier(""))
    }
}
