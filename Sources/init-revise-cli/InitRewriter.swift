import SwiftSyntax

final class InitRewriter: SyntaxRewriter {
    private let expressionTypes: [ExpressionType]
    private var tokensToRemove: [TokenSyntax] = []
    
    init(expressionTypes: [ExpressionType]) {
        self.expressionTypes = expressionTypes
    }
    
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard tokensToRemove.isEmpty else {
            tokensToRemove.remove(at: 0)
            return remove(token: token)
        }
        guard let targetToken = targetToken(token) else { return super.visit(token) }
        return revise(targetToken)
    }
    
    private func targetToken( _ token: TokenSyntax) -> TokenSyntax? {
        guard token.tokenKind == .prefixPeriod else { return nil }
        guard let initToken = token.nextToken, initToken.tokenKind == .initKeyword else { return nil }
        guard let leftParanToken = token.nextToken?.nextToken, leftParanToken.tokenKind == .leftParen else { return nil }
        tokensToRemove = [initToken]
        return token
    }
    
    private func revise(_ token: TokenSyntax) -> TokenSyntax {
        let offset = token.byteRange.endOffset - 1
        guard let actualExpressionType = expressionTypes.first(where: { $0.offset == offset }) else { return token }
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
    
    // there is no optional initialiation
    private func stripOptionalIfNeeded(type: String) -> String {
        guard type.last == "?" else { return type }
        return String(type.dropLast())
    }
    
    private func remove(token: TokenSyntax) -> TokenSyntax {
        return token.withKind(.identifier(""))
    }
}
