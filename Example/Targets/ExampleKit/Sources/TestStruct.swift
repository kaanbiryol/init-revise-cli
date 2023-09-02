import Foundation

public struct Test {
    public let value: String
    
    public struct ViewModel {
        public let value: String
        
        public init(value: String) {
            self.value = value
        }
    }
    
    public init(value: String) {
        self.value = value
    }
    
}
