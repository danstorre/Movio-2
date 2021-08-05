
import XCTest
import MovioSuggestedMoviesFeed

class URLSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedErrorOnInvalidValues: Error {}
    
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void) {
        session.dataTask(with: url, completionHandler: {data,response,error in
            if let error = error {
                completion(.failure(error: error))
            } else if let data = data, data.count > 0, let response = response as? HTTPURLResponse {
                completion(.success(response: response, data: data))
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
        
        makeSUT().getDataFrom(url: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_deliversErrorOnRequestError() {
        let clientError = NSError(domain: "a domain error from Network", code: 1)
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: clientError) as NSError?
        
        XCTAssertEqual(receivedError?.domain, clientError.domain)
        XCTAssertEqual(receivedError?.code, clientError.code)
    }
    
    func test_getFromURL_deliversFailureWhenAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_deliversResultOnDataAndHTTPResponse() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let exp = XCTestExpectation(description: "wait for result")
        
        makeSUT().getDataFrom(url: anyURL()) { result in
            switch result {
            case let .success(response: receivedResponse, data: receivedData):
                XCTAssertEqual(response.statusCode, receivedResponse.statusCode)
                XCTAssertEqual(response.url, receivedResponse.url)
                XCTAssertEqual(data, receivedData)
            default:
                XCTFail("Expected success, got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    private func anyURL() -> URL {
        URL(string: "http://a-url.com")!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "a domain error", code: 1, userInfo: nil)
    }
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(instance: sut, file: file, line: line)
        return sut
    }
    
    private func trackForMemoryLeak(instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "instance should be nil. potential memory leak.", file: file, line: line)
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = XCTestExpectation(description: "wait for failure")
        
        var capturedError: Error?
        
        makeSUT(file: file, line: line).getDataFrom(url: anyURL()) { result in
            switch result {
            case let .failure(error):
                capturedError = error
            default:
                XCTFail("Expected failure, got \(result) instead.", file: file, line: line)
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
