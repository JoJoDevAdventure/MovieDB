//
//  Movie+CoreDataClass.swift
//  Movie DB
//
//  Created by Jonas Frey on 05.02.21.
//  Copyright © 2021 Jonas Frey. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Movie)
public class Movie: Media {
    
    /// Creates a new `Movie` object.
    convenience init(context: NSManagedObjectContext, tmdbData: TMDBData) {
        self.init(context: context)
        self.initMedia(type: .movie, tmdbData: tmdbData)
    }
    
    override func initMedia(type: MediaType, tmdbData: TMDBData) {
        super.initMedia(type: type, tmdbData: tmdbData)
        // This is a movie, therefore the TMDBData needs to have movie specific data
        let movieData = tmdbData.movieData!
        self.releaseDate = movieData.releaseDate
        self.runtime = movieData.runtime
        self.budget = movieData.budget
        self.revenue = movieData.revenue
        self.tagline = movieData.tagline
        self.isAdult = movieData.isAdult
        self.imdbID = movieData.imdbID
    }

}
