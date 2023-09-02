import SwiftSyntax

final class InitReviser: SyntaxRewriter {
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
    
    // .init(
    private func targetToken( _ token: TokenSyntax) -> TokenSyntax? {
        guard token.tokenKind == .prefixPeriod else { return nil }
        guard let initToken = token.nextToken, initToken.tokenKind == .initKeyword else { return nil }
        guard let leftParanToken = token.nextToken?.nextToken, leftParanToken.tokenKind == .leftParen else { return nil }
        tokensToRemove = [initToken]
        return token
    }
    
    // . replaces // sourcekit seems to give us the end offset?
    private func revise(_ token: TokenSyntax) -> TokenSyntax {
        let offset = token.byteRange.endOffset - 1
        let prev = token.previousToken?.byteRange.offset
        guard let actualExpressionType = expressionTypes.first(where: { $0.offset == offset }) else { return token }
        let newToken = token.withKind(.identifier(actualExpressionType.type))
        return newToken
    }
    
    private func remove(token: TokenSyntax) -> TokenSyntax {
        return token.withKind(.identifier(""))
    }
}
