
import Foundation

enum FeedSuggestedMoviesLoaderResult {
    case success([FeedSuggestedMovie])
    case error(Error)
}

protocol FeedSuggestedMoviesLoader {
    func load(completion: @escaping (FeedSuggestedMoviesLoaderResult) -> Void)
}
