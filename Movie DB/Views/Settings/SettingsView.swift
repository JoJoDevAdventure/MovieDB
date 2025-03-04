//
//  SettingsView.swift
//  Movie DB
//
//  Created by Jonas Frey on 26.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI
import JFSwiftUI
import CoreData
import CSVImporter

struct SettingsView: View {
    // Reference to the config instance
    @ObservedObject private var preferences = JFConfig.shared
    @State private var library: MediaLibrary = .shared
    
    @Environment(\.managedObjectContext) private var managedObjectContext: NSManagedObjectContext
    
    @State private var config = SettingsViewConfig()
    
    var body: some View {
        // TODO: Should settings really use a loading screen?
        LoadingView(
            isShowing: $config.isLoading,
            text: config.loadingText ?? Strings.Settings.loadingPlaceholder
        ) {
            NavigationView {
                Form {
                    PreferencesSection(config: $config, reloadHandler: self.reloadMedia)
                    if !Utils.purchasedPro() {
                        ProSection(config: $config)
                    }
                    ImportExportSection(config: $config)
                    LibraryActionsSection(config: $config, reloadHandler: self.reloadMedia)
                }
                .environmentObject(preferences)
                .navigationTitle(Strings.TabView.settingsLabel)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink(
                            Strings.Settings.navBarButtonLegal,
                            destination: LegalView()
                        )
                    }
                }
            }
        }
    }
    
    func reloadMedia() {
        self.config.showProgress(Strings.Settings.ProgressView.reloadLibrary)
        
        // Perform the reload in the background on a different thread
        Task(priority: .userInitiated) {
            print("Starting reload...")
            do {
                // Reload and show the result
                try await self.library.reloadAll()
                await MainActor.run {
                    self.config.hideProgress()
                    AlertHandler.showSimpleAlert(
                        title: Strings.Settings.Alert.reloadCompleteTitle,
                        message: Strings.Settings.Alert.reloadCompleteMessage
                    )
                }
            } catch {
                print("Error reloading media objects: \(error)")
                await MainActor.run {
                    self.config.hideProgress()
                    AlertHandler.showError(
                        title: Strings.Settings.Alert.reloadErrorTitle,
                        error: error
                    )
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct SettingsViewConfig {
    var showingProgress = false
    private(set) var progressText: String = ""
    var isLoading = false
    var loadingText: String?
    var languageChanged = false
    var regionChanged = false
    var isShowingProInfo = false
    
    mutating func showProgress(_ text: String) {
        self.showingProgress = true
        self.progressText = text
    }
    
    mutating func hideProgress() {
        self.showingProgress = false
        self.progressText = ""
    }
}
