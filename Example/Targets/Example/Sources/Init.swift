import ExampleKit

struct Init {
    func test() {
        doSomething(model: .init(value: ""))
    }
}

struct AppStruct {
    let value: String
}

func doSomethingInApp(appStruct: AppStruct) -> String {
    return appStruct.value
}
