import Foundation
import XCTest

@testable import Example

final class ExampleTests: XCTestCase {
    func test_twoPlusTwo_isFour() {
        let value = doSomethingInApp(appStruct: .init(value: "value"))
        XCTAssertEqual(value, "value")
    }
}
