
import XCTest
import MovioSuggestedMoviesFeed

class HTTPSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
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
    
    func test_getDataFrom_deliversFailureWithErrorWhenSessionFails() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://a-url.com")!
        
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        URLProtocolStub.stub(url: url, error: clientError)
        
        let sut = HTTPSessionHTTPClient()
        
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
        URLProtocolStub.stopInterceptingRequests()
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stubs = [URL: Stub]()
        
        struct Stub {
            let error: Error?
        }
        
        static func stub(url: URL, error: Error? = nil) {
            stubs[url] = Stub(error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        override static func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            return stubs[url] != nil
        }
        
        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
                return
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
        
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
