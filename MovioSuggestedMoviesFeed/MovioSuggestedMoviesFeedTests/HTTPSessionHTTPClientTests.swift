
import XCTest
import MovioSuggestedMoviesFeed

class URLSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedErrorOnInvalidValues: Error {}
    
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void) {
        session.dataTask(with: url, completionHandler: {_,_,error in
            if let error = error {
                completion(.failure(error: error))
            } else {
                completion(.failure(error: UnexpectedErrorOnInvalidValues()))
            }
        }).resume()
    }
}

class HTTPSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsTheCorrectGETRequestWithURL() {
        let url = anyURL()
        
        let exp = XCTestExpectation(description: "wait for url")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual("GET", request.httpMethod)
            
            exp.fulfill()
        }
        
        URLSessionHTTPClient().getDataFrom(url: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_deliversErrorOnRequestError() {
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: clientError) as NSError?
        
        XCTAssertEqual(receivedError?.domain, clientError.domain)
        XCTAssertEqual(receivedError?.code, clientError.code)
    }
    
    func test_getFromURL_deliversFailureWhenAllValuesAreNil() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    }
    
    // MARK: - Helper Methods
    private func anyURL() -> URL {
        URL(string: "http://a-url.com")!
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = XCTestExpectation(description: "wait for failure")
        
        var capturedError: Error?
        
        URLSessionHTTPClient().getDataFrom(url: anyURL()) { result in
            switch result {
            case let .failure(error):
                capturedError = error
            default:
                XCTFail("Expected failure, got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return capturedError
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stubs: Stub?
        static var requestObserver: ((URLRequest) -> Void)?
        
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stubs = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequest(_ observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        override static func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stubs else {
                return
            }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
        
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
