import Foundation

func doSomething(nestedStruct: TestNestedStruct.NestedStruct) {
    print(nestedStruct.nestedParam)
}
 
class Test {
    init() {
        doSomething(nestedStruct: .init(nestedParam: ""))
    }
}
