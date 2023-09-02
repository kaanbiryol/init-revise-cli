import ExampleKit

typealias MyType = Int

func doSomething(model: Test.ViewModel) {
    print(model.value)
}

func doSomethingOptional(model: Test.ViewModel?) {
    print(model?.value)
}

func doSomethingArray(model: [Test.ViewModel]) {
    print(model.count)
}

func doSomethingArrayOptional(model: [Test.ViewModel?]) {
    print(model.count)
}

func doSomethingOptionalArray(model: [Test.ViewModel]?) {
    print(model?.count)
}

func doSomethingTypealias(model: MyType) {
    print(model)
}
 
class Revise {
    init() {
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
