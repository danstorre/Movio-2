
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
    
    func test_getFromURL_deliversErrorOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://a-url.com")!
        
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: clientError)
        
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
        static var stubs = [URL: Stub]()
        
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error? = nil) {
            stubs[url] = Stub(data: data, response: response, error: error)
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
