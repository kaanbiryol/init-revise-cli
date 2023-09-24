import Foundation
import XCTest

@testable import ExampleKit

final class ExampleKitTests: XCTestCase {
    func test_example() {
        let value = doSomethingForTestTarget(model: .init(value: "value"))
        XCTAssertEqual(value, "value")
    }
}
