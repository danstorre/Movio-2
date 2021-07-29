
import XCTest
import MovioSuggestedMoviesFeed

class HTTPSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void) {
        session.dataTask(with: url, completionHandler: {_,_,error in
            if let error = error {
                completion(.failure(error: error))
            }
        }).resume()
    }
}

class HTTPSessionHTTPClientTests: XCTestCase {
    
    func test_getDataFrom_resumesDataTask(){
        let url = URL(string: "http://a-url.com")!
        
        let task = FakeURLSessionDataTask()
        let session = URLSessionSpy()
        
        session.stub(url: url, task: task)
        
        let sut = HTTPSessionHTTPClient(session: session)
        
        sut.getDataFrom(url: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getDataFrom_deliversFailureWithErrorWhenSessionFails() {
        let url = URL(string: "http://a-url.com")!
        
        let session = URLSessionSpy()
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        session.stub(url: url, error: clientError)
        
        let sut = HTTPSessionHTTPClient(session: session)
        
        let exp = XCTestExpectation(description: "wait for expectation")
        sut.getDataFrom(url: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual( receivedError.domain, clientError.domain)
                XCTAssertEqual( receivedError.code, clientError.code)
            default:
                XCTFail("expected to receive \(clientError), got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class URLSessionSpy: URLSession {
        var stubs = [URL: Stub]()
        
        struct Stub {
            let dataTask: URLSessionDataTask
            let error: Error?
        }
        
        func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(dataTask: task, error: error)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("couldn't find the task with the given \(url)")
            }
            
            if let error = stub.error {
                completionHandler(nil, nil, error)
            }
            
            return stub.dataTask
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }

}
