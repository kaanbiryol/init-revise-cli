import Foundation

public final class ExampleKit {
    public static func hello() {
        print("Hello, from your Kit framework")
    }
}

public typealias MyType = Int

public func doSomething(model: Test.ViewModel) {
    print(model.value)
}

public func doSomethingOptional(model: Test.ViewModel?) {
    print(model?.value)
}

public func doSomethingArray(model: [Test.ViewModel]) {
    print(model.count)
}

public func doSomethingArrayOptional(model: [Test.ViewModel?]) {
    print(model.count)
}

public func doSomethingOptionalArray(model: [Test.ViewModel]?) {
    print(model?.count)
}

public func doSomethingTypealias(model: MyType) {
    print(model)
}
 
class Revise {
    public init() {
        doSomething(model: .init(value: "1"))
        doSomethingOptional(model: .init(value: "2"))
        doSomethingArray(model: [
            .init(value: "3"),
            .init(value: "4"),
            .init(value: "5")
        ])
        doSomethingArrayOptional(model: [
            .init(value: "6"),
            .init(value: "7"),
            nil
        ])
        doSomethingOptionalArray(model: [
            .init(value: "8")
        ])
        doSomethingTypealias(model: 9)
    }
}
