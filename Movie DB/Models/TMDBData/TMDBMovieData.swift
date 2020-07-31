//
//  TMDBMovieData.swift
//  Movie DB
//
//  Created by Jonas Frey on 25.06.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation

class TMDBMovieData: TMDBData {

    /// The date, the movie was released
    var releaseDate: Date?
    /// Runtime in minutes
    var runtime: Int?
    /// The production budget in dollars
    var budget: Int
    /// The revenue in dollars
    var revenue: Int
    /// The tagline of the movie
    var tagline: String?
    /// Whether the movie is an adult movie
    var isAdult: Bool
    
    init(id: Int, title: String, originalTitle: String, imagePath: String?, genres: [Genre], overview: String?, status: MediaStatus, originalLanguage: String, imdbID: String?, productionCompanies: [ProductionCompany], homepageURL: String?, popularity: Float, voteAverage: Float, voteCount: Int, releaseDate: Date?, runtime: Int?, budget: Int, revenue: Int, tagline: String?, isAdult: Bool) {
        self.releaseDate = releaseDate
        self.runtime = runtime
        self.budget = budget
        self.revenue = revenue
        self.tagline = tagline
        self.isAdult = isAdult
        super.init(id: id, title: title, originalTitle: originalTitle, imagePath: imagePath, genres: genres, overview: overview, status: status, originalLanguage: originalLanguage, imdbID: imdbID, productionCompanies: productionCompanies, homepageURL: homepageURL, popularity: popularity, voteAverage: voteAverage, voteCount: voteCount)
    }
    
    // MARK: - Codable Conformance
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawReleaseDate = try container.decode(String.self, forKey: .releaseDate)
        self.releaseDate = JFUtils.tmdbDateFormatter.date(from: rawReleaseDate)
        
        self.runtime = try container.decode(Int?.self, forKey: .runtime)
        self.budget = try container.decode(Int.self, forKey: .budget)
        self.revenue = try container.decode(Int.self, forKey: .revenue)
        self.tagline = try container.decode(String?.self, forKey: .tagline)
        self.isAdult = try container.decode(Bool.self, forKey: .isAdult)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        // Encode the dates using the tmdbDateFormatter, so init reads them correctly again
        var rawReleaseDate: String? = nil
        if let releaseDate = releaseDate {
            rawReleaseDate = JFUtils.tmdbDateFormatter.string(from: releaseDate)
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawReleaseDate, forKey: .releaseDate)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(budget, forKey: .budget)
        try container.encode(revenue, forKey: .revenue)
        try container.encode(tagline, forKey: .tagline)
        try container.encode(isAdult, forKey: .isAdult)
    }
    
    enum CodingKeys: String, CodingKey {
        case releaseDate = "release_date"
        case runtime
        case budget
        case revenue
        case tagline
        case isAdult = "adult"
    }
    
    // MARK: - Hashable Conformance
    
    override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(releaseDate)
        hasher.combine(runtime)
        hasher.combine(budget)
        hasher.combine(revenue)
        hasher.combine(tagline)
        hasher.combine(isAdult)
    }
}
