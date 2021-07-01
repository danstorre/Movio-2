import Foundation

public enum HTTPRequestResult {
    case success(response: HTTPURLResponse, data: Data)
    case failure(error: Error)
}

public protocol HTTPClient {
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void)
}

public final class RemoteFeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public enum FeedSuggestedMoviesResult {
        case success([FeedSuggestedMovie])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (FeedSuggestedMoviesResult) -> ()) {
        client.getDataFrom(url: url) { result in
            switch result {
            case let .success(response: response, data: _):
                if response.statusCode == 200 {
                    completion(.success([]))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.noConnectivity))
            }
        }
    }
}
