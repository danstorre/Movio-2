
import Foundation

public enum HTTPRequestResult {
    case success(response: HTTPURLResponse, data: Data)
    case failure(error: Error)
}

public protocol HTTPClient {
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void)
}
