struct ExpressionTypeResponse: Codable {
    let types: [ExpressionType]
    
    enum CodingKeys: String, CodingKey {
        case types = "key.expression_type_list"
    }
}

struct ExpressionType: Codable {
    let length: Int
    let offset: Int
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case length = "key.expression_length"
        case offset = "key.expression_offset"
        case type = "key.expression_type"
    }
}

func expressionRequest(sourceFile: String, compilerArgs: [String]) -> String {
    var request = """
    key.request: source.request.expression.type
    key.sourcefile: "\(sourceFile)"
    key.toolchains:
        - \"com.apple.dt.toolchain.XcodeDefault\"
    key.compilerargs:\n
    """
    for arg in compilerArgs {
        let argString = """
        - "\(arg)"\n
    """
        request.append(argString)
    }
    return request
}
