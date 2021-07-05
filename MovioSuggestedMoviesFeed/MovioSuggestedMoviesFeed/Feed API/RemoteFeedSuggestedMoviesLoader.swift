
import Foundation

public final class RemoteFeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedSuggestedMovie])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> ()) {
        client.getDataFrom(url: url) { result in
            switch result {
            case let .success(response: response, data: data):
                do {
                    let items = try RemoteFeedSuggestedMoviesParser.parse(data: data,
                                                                          response: response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.noConnectivity))
            }
        }
    }
}
