//
//  LanguageChooser.swift
//  Movie DB
//
//  Created by Jonas Frey on 13.05.21.
//  Copyright © 2021 Jonas Frey. All rights reserved.
//

import SwiftUI

struct LanguageChooser: View {
    @ObservedObject private var config = JFConfig.shared
    
    var body: some View {
        NavigationView {
            if config.availableLanguages.isEmpty {
                Text(
                    "languageChooser.loadingText",
                    // swiftlint:disable:next line_length
                    comment: "Placeholder text to display while loading the available languages in the language chooser onboarding screen"
                )
                .task(priority: .userInitiated) {
                    do {
                        try await Utils.updateTMDBLanguages()
                    } catch {
                        AlertHandler.showError(
                            title: String(
                                localized: "languageChooser.alert.errorLoading.title",
                                // swiftlint:disable:next line_length
                                comment: "Title of an alert informing the user about an error while loading the available languages"
                            ),
                            error: error
                        )
                    }
                }
                .navigationTitle(String(
                    localized: "languageChooser.navBar.title",
                    comment: "The navigation bar title for the language chooser view"
                ))
            } else {
                let proxy = Binding<String?>(get: { config.language }, set: { config.language = $0 ?? "" })
                List(config.availableLanguages, id: \.self, selection: proxy) { (code: String) in
                    Text(Locale.current.localizedString(forIdentifier: code) ?? code)
                        .tag(code)
                }
                .environment(\.editMode, .constant(.active))
                .onChange(of: config.language) { _ in
                    print("Language changed to \(config.language)")
                }
                .navigationTitle(String(
                    localized: "languageChooser.navBar.title",
                    comment: "The navigation bar title for the language chooser view"
                ))
            }
        }
    }
}

struct LanguageChooser_Previews: PreviewProvider {
    static var previews: some View {
        LanguageChooser()
    }
}
