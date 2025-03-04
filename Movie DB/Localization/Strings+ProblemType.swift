//
//  Strings+ProblemType.swift
//  Movie DB
//
//  Created by Jonas Frey on 23.05.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

// swiftlint:disable superfluous_disable_command nesting line_length file_length type_body_length

extension Strings {
    enum ProblemType {
        static let duplicateMedia = String(
            localized: "problemType.duplicateMedia.description",
            comment: "A type of library problem (e.g. duplicate medias)"
        )
        static let duplicateMediaRecovery = String(
            localized: "problemType.duplicateMedia.recovery",
            comment: "A recovery suggestion to resolve a library problem (e.g. duplicate medias)"
        )
    }
}
