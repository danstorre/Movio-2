
import XCTest

extension XCTestCase {
    func trackForMemoryLeak(
        instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "instance should be nil. potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
