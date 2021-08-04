
import XCTest
import MovioSuggestedMoviesFeed

class URLSessionHTTPClient {
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
    
    func test_getFromURL_performsTheCorrectGETRequestWithURL() {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "http://a-url.com")!
        
        let exp = XCTestExpectation(description: "wait for url")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual("GET", request.httpMethod)
            
            exp.fulfill()
        }
        
        URLSessionHTTPClient().getDataFrom(url: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_deliversErrorOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://a-url.com")!
        
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        URLProtocolStub.stub(data: nil, response: nil, error: clientError)
        
        let sut = URLSessionHTTPClient()
        
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
