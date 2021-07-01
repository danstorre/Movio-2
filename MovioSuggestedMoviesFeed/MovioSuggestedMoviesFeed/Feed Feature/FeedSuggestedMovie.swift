//
//  Movie.swift
//  MovioSuggestedMoviesFeed
//
//  Created by Daniel Torres on 6/29/21.
//

import Foundation

public struct FeedSuggestedMovie: Equatable {
    public let id: UUID
    public let title: String
    public let plot: String
    public let poster: URL?
    
    public init(id: UUID, title: String, plot: String, poster: URL? = nil) {
        self.id = id
        self.title = title
        self.plot = plot
        self.poster = poster
    }
}
