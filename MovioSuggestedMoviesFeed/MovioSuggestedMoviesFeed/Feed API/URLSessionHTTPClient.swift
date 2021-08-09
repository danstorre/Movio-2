
import Foundation

public class URLSessionHTTPClient: HTTPClient {
    let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedErrorOnInvalidValues: Error {}
    
    public func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void) {
        session.dataTask(with: url, completionHandler: {data,response,error in
            if let error = error {
                completion(.failure(error: error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(response: response, data: data))
            } else {
                completion(.failure(error: UnexpectedErrorOnInvalidValues()))
            }
        }).resume()
    }
}
