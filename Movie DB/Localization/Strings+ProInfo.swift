//
//  Strings+ProInfo.swift
//  Movie DB
//
//  Created by Jonas Frey on 24.05.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import Foundation

// swiftlint:disable superfluous_disable_command nesting line_length file_length type_body_length

extension Strings {
    enum ProInfo {
        static let navBarTitle = String(
            localized: "proInfo.navBar.title",
            comment: "The navigation bar title for the pro info view"
        )
        static let buyButtonLabelDisabled = String(
            localized: "proInfo.buyButton.label.disabled",
            comment: "The button label in the pro info view indicating that the user already bought pro."
        )
        static let buyButtonLabel = String(
            localized: "proInfo.buyButton.label \("4,99 $")",
            comment: "The button label in the pro info view displaying the price to buy the pro version of the app. The parameter is the localized and formatted price."
        )
        static let restoreButtonLabel = String(
            localized: "proInfo.button.restore",
            comment: "The label for the restore button in the pro info view"
        )
        static let navBarButtonCancelLabel = String(
            localized: "proInfo.navBar.button.cancel",
            comment: "The label for the cancel button in the navigation bar of the pro info view"
        )
        static func introText(_ limit: Int) -> String {
            String(
                localized: "proInfo.introText \(limit)",
                comment: "Text in pro info view that explains the media limit which buying pro removes. The parameter is the amount of objects one can add in the free version"
            )
        }
        static let aboutMeHeader = String(
            localized: "proInfo.aboutMe.header",
            comment: "The header of the 'about me' paragraph in the pro info view"
        )
        static let aboutMeText = String(
            localized: "proInfo.aboutMe.text",
            comment: "The 'about me' text in the pro info view"
        )
        
        enum Alert {
            static let buyProErrorTitle = String(
                localized: "settings.alert.errorBuyingPro.title",
                comment: "Title of an alert informing the user that there was an error with the in-app purchase"
            )
            static let buyProErrorMessage = String(
                localized: "settings.alert.errorBuyingPro.message",
                comment: "Message of an alert informing the user that the purchase could not be completed because the in-app purchase could not be found / is not configured"
            )
        }
    }
}
