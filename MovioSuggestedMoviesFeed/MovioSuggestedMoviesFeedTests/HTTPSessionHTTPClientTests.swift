
import XCTest

class HTTPSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func getDataFrom(url: URL) {
        session.dataTask(with: url, completionHandler: {_,_,_ in }).resume()
    }
}

class HTTPSessionHTTPClientTests: XCTestCase {
    
    func test_getDataFrom_resumesDataTask(){
        let url = URL(string: "http://a-url.com")!
        
        let task = FakeURLSessionDataTask()
        let session = URLSessionSpy()
        
        session.stub(url: url, task: task)
        
        let sut = HTTPSessionHTTPClient(session: session)
        
        sut.getDataFrom(url: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    private class URLSessionSpy: URLSession {
        var stubs = [URL: URLSessionDataTask]()
        
        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let task = stubs[url] else {
                fatalError("couldn't find the task with the given \(url)")
            }
            
            return task
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }

}
