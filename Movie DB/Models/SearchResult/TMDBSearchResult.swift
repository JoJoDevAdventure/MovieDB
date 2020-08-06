//
//  TMDBSearchResult.swift
//  Movie DB
//
//  Created by Jonas Frey on 29.06.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI

/// Represents a search result from the TMDBAPI search call
class TMDBSearchResult: Decodable, Identifiable {
    // Basic Data
    /// The TMDB ID of the media
    var id: Int
    /// The name of the media
    var title: String
    /// The type of media
    var mediaType: MediaType
    /// The path of the media poster image on TMDB
    var imagePath: String?
    /// A short media description
    var overview: String?
    /// The original tile of the media
    var originalTitle: String
    /// The language the movie was originally created in as an ISO-639-1 string (e.g. 'en')
    var originalLanguage: String
    
    // TMDB Scoring
    /// The popularity of the media on TMDB
    var popularity: Float
    /// The average rating on TMDB
    var voteAverage: Float
    /// The number of votes that were cast on TMDB
    var voteCount: Int
    /// Whether the result is a movie and is for adults only
    var isAdultMovie: Bool? { (self as? TMDBMovieSearchResult)?.isAdult }
    
    /// Creates a new `TMDBSearchResult` object with the given values
    init(id: Int, title: String, mediaType: MediaType, imagePath: String? = nil, overview: String? = nil, originalTitle: String, originalLanguage: String, popularity: Float, voteAverage: Float, voteCount: Int) {
        self.id = id
        self.title = title
        self.mediaType = mediaType
        self.imagePath = imagePath
        self.overview = overview
        self.originalTitle = originalTitle
        self.originalLanguage = originalLanguage
        self.popularity = popularity
        self.voteAverage = voteAverage
        self.voteCount = voteCount
    }
    
    // MARK: - Codable Conformance
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeAny(String.self, forKeys: [.title, .showTitle])
        self.mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        self.imagePath = try container.decode(String?.self, forKey: .imagePath)
        self.overview = try container.decode(String?.self, forKey: .overview)
        self.originalTitle = try container.decodeAny(String.self, forKeys: [.originalTitle, .originalShowTitle])
        self.originalLanguage = try container.decode(String.self, forKey: .originalLanguage)
        self.popularity = try container.decode(Float.self, forKey: .popularity)
        self.voteAverage = try container.decode(Float.self, forKey: .voteAverage)
        self.voteCount = try container.decode(Int.self, forKey: .voteCount)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case showTitle = "name"
        case mediaType = "media_type"
        case imagePath = "poster_path"
        case overview
        case originalTitle = "original_title"
        case originalShowTitle = "original_name"
        case originalLanguage = "original_language"
        case popularity
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
