import Foundation

public enum HTTPRequestResult {
    case success(response: HTTPURLResponse)
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
        case success
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (FeedSuggestedMoviesResult) -> ()) {
        client.getDataFrom(url: url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.noConnectivity))
            }
        }
    }
}
