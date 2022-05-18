//
//  LanguagePickerView.swift
//  Movie DB
//
//  Created by Jonas Frey on 23.04.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject var preferences: JFConfig
    
    var body: some View {
        Picker("Language", selection: $preferences.language) {
            if preferences.availableLanguages.isEmpty {
                Text(
                    "settings.languagePicker.loadingText",
                    comment: "Placeholder text to display while loading the available languages in the settings"
                )
                .task(priority: .userInitiated) { await self.updateLanguages() }
            } else {
                ForEach(preferences.availableLanguages, id: \.self) { code in
                    let languageName = Locale.current.localizedString(forIdentifier: code) ?? code
                    Text(languageName)
                        .tag(code)
                }
            }
        }
    }
    
    private func updateLanguages() async {
        if preferences.availableLanguages.isEmpty {
            // Load the TMDB Languages
            do {
                try await Utils.updateTMDBLanguages()
            } catch {
                // We need to report the error, otherwise the user may be confused due to the loading text
                await MainActor.run {
                    print(error)
                    AlertHandler.showError(
                        title: String(
                            localized: "settings.languagePicker.alert.errorLoading.title",
                            // No way to split up a StaticString into multiple lines
                            // swiftlint:disable:next line_length
                            comment: "Title of an alert informing the user about an error while reloading the available languages"
                        ),
                        error: error
                    )
                }
            }
        }
    }
}

struct LanguagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LanguagePickerView()
                .environmentObject(JFConfig.shared)
        }
    }
}
