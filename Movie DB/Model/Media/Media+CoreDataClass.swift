//
//  Media.swift
//  Movie DB
//
//  Created by Jonas Frey on 24.06.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import JFSwiftUI
import CloudKit
import CoreData

/// Represents a media object in the library
@objc(Media)
public class Media: NSManagedObject {
    
    // MARK: - Missing Information
    
    /// Initialize all Media properties from the given TMDBData
    /// Call this function from `Show.init` or `Movie.init` to properly set up the common properties
    func initMedia(type: MediaType, tmdbData: TMDBData) {
        // We have to initialize missingInformation first, because the other setters may modify it
        self.missingInformation = Set(MediaInformation.allCases)
        self.personalRating = .noRating
        self.tags = []
        
        self.id = MediaLibrary.shared.nextID
        self.type = type
        
        // Set all properties from the tmdbData object
        self.tmdbID = tmdbData.id
        self.title = tmdbData.title
        self.originalTitle = tmdbData.originalTitle
        self.imagePath = tmdbData.imagePath
        self.genres = Set(tmdbData.genres)
        self.overview = tmdbData.overview
        self.status = tmdbData.status
        self.originalLanguage = tmdbData.originalLanguage
        self.productionCompanies = Set(tmdbData.productionCompanies)
        self.homepageURL = tmdbData.homepageURL
        self.popularity = tmdbData.popularity
        self.voteAverage = tmdbData.voteAverage
        self.voteCount = tmdbData.voteCount
        self.cast = Set(tmdbData.cast)
        self.keywords = tmdbData.keywords
        self.translations = tmdbData.translations
        self.videos = Set(tmdbData.videos)
    }
    
    public override func awakeFromInsert() {
        // We have to initialize missingInformation first, because the other setters may modify it
        self.missingInformation = Set(MediaInformation.allCases)
        self.tags = []
    }
    
    // MARK: - Functions
    
    /// Triggers a reload of the thumbnail using the `imagePath` in `tmdbData`
    func loadThumbnail(force: Bool = false) {
        guard thumbnail == nil || force else {
            // Thumbnail already present, don't download again, override with force parameter
            return
        }
        guard let imagePath = imagePath, !imagePath.isEmpty else {
            // No image path set, no image to load
            return
        }
        print("[\(self.title)] Loading thumbnail...")
        JFUtils.loadImage(urlString: JFUtils.getTMDBImageURL(path: imagePath)) { image in
            // Only update, if the image is not nil, dont delete existing images
            if let image = image {
                let thumbnail = Thumbnail(context: self.managedObjectContext!, pngData: image.pngData())
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }
    
    /// Updates the media object with the given data
    /// - Parameter tmdbData: The new data
    func update(tmdbData: TMDBData) throws {
        // Set all TMDBData properties again
        self.initMedia(type: type, tmdbData: tmdbData)
        try self.managedObjectContext?.save()
    }
    
    // MARK: - Repairable Conformance
    
    /// Attempts to identify problems and repair this media object by reloading the thumbnail, removing corrupted tags and re-loading the cast information
    /// - Parameter progress: A binding for the progress of the repair status
    /// - Returns: The number of fixed and not fixed problems
    func repair(progress: Binding<Double>? = nil) -> RepairProblems {
        // We have to check the following things:
        // tmdbData, thumbnail, tags, missingInformation
        let progressStep = 1.0/3.0
        let group = DispatchGroup()
        var fixed = 0
        let notFixed = 0
        // If we have no TMDBData, we have no tmdbID and therefore no possibility to reload the data.
        progress?.wrappedValue += progressStep
        // Thumbnail
        if self.thumbnail == nil && imagePath != nil {
            loadThumbnail()
            fixed += 1
            print("[Verify] '\(title)' (\(id)) is missing the thumbnail. Trying to fix it.")
        }
        progress?.wrappedValue += progressStep
        // Tags
        for tag in tags {
            // If the tag does not exist, remove it
            if !TagLibrary.shared.tags.map(\.id).contains(tag) {
                DispatchQueue.main.async {
                    self.tags.removeFirst(tag)
                    fixed += 1
                    print("[Verify] '\(self.title)' (\(self.id)) has invalid tags. Removed the invalid tags.")
                }
            }
        }
        progress?.wrappedValue += progressStep
        // Missing Information
        DispatchQueue.main.async {
            self.missingInformation = .init()
            if self.personalRating == .noRating {
                self.missingInformation.insert(.rating)
            }
            if self.watchAgain == nil {
                self.missingInformation.insert(.watchAgain)
            }
            if self.tags.isEmpty {
                self.missingInformation.insert(.tags)
            }
        }
        progress?.wrappedValue += progressStep
        
        
        // TODO: Check, if tmdbData is complete, nothing is missing (e.g. cast, seasons, translations, keywords, ...)
        
        group.wait()
        // Make sure the progress is 100% (may be less due to rounding errors)
        progress?.wrappedValue = 1.0
        if fixed == 0 && notFixed == 0 {
            return .none
        } else {
            return .some(fixed: fixed, notFixed: notFixed)
        }
    }
}

extension Media {
    /// Represents a user-provided information about a media object.
    /// This enum only contains the information, that will cause the object to show up in the Problems tab, when missing
    public enum MediaInformation: String, CaseIterable, Codable {
        case rating
        case watched
        case watchAgain
        case tags
        // Notes are not required for the media object to be complete
    }
    
    enum MediaError: Error {
        case noData
        case encodingFailed(String)
    }
}
