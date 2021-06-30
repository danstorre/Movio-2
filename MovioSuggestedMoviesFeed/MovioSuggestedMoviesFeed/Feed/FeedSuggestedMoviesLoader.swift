//
//  FeedSuggestedMoviesLoader.swift
//  MovioSuggestedMoviesFeed
//
//  Created by Daniel Torres on 6/29/21.
//

import Foundation

enum FeedSuggestedMoviesLoaderResult {
    case success([FeedSuggestedMovie])
    case error(Error)
}

protocol FeedSuggestedMoviesLoader {
    func load(completion: @escaping (FeedSuggestedMoviesLoaderResult) -> Void)
}
