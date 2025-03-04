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
        Picker(Strings.Settings.languageNavBarTitle, selection: $preferences.language) {
            if preferences.availableLanguages.isEmpty {
                Text(Strings.Settings.languagePickerLoadingText)
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
                        title: Strings.Settings.Alert.errorLoadingLanguagesTitle,
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
