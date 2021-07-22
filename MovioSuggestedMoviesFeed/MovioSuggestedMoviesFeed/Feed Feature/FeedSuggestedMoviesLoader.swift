
import Foundation

public enum FeedSuggestedMoviesLoaderResult {
    case success([FeedSuggestedMovie])
    case failure(Error)
}

protocol FeedSuggestedMoviesLoader {
    func load(completion: @escaping (FeedSuggestedMoviesLoaderResult) -> Void)
}
