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

// TODO: Too long!
struct SettingsView: View {
    // Reference to the config instance
    @ObservedObject private var config = JFConfig.shared
    @ObservedObject private var library = MediaLibrary.shared
    
    @Environment(\.managedObjectContext) private var managedObjectContext: NSManagedObjectContext
            
    @State private var updateInProgress = false
    @State private var reloadInProgress = false
    @State private var documentPicker: DocumentPicker?
    @State private var isLoading = false
    @State private var loadingText: String?
    @State private var importLogger: TagImporter.BasicLogger?
    @State private var importLogShowing = false
    @State private var languageChanged = false
    @State private var isShowingProInfo = false
    
    var body: some View {
        LoadingView(isShowing: $isLoading, text: self.loadingText ?? NSLocalizedString("Loading...")) {
            NavigationView {
                Form {
                    Section {
                        Toggle("Show Adult Content", isOn: $config.showAdults)
                        LanguagePickerView(config: config)
                            .onChange(of: config.language) { languageCode in
                                print("Language changed to \(languageCode)")
                                self.languageChanged = true
                            }
                    }
                    // MARK: - Buy Pro
                    if !Utils.purchasedPro() {
                        Section {
                            Button("Buy Pro", action: { self.isShowingProInfo = true })
                                .popover(isPresented: $isShowingProInfo) {
                                    ProInfoView()
                                }
                        }
                    }
                    Section {
                        // MARK: - Import Button
                        Button("Import Media", action: self.importMedia)
                            // MARK: Document Picker
                            .popover(isPresented: .init(get: {
                                #if targetEnvironment(macCatalyst)
                                return false
                                #else
                                return self.documentPicker != nil
                                #endif
                            }, set: { newState in
                                // If the new state is "hidden"
                                if newState == false {
                                    self.documentPicker = nil
                                }
                            })) {
                                self.documentPicker!
                            }
                        
                        // MARK: - Export Button
                        Button(action: self.exportMedia) {
                            Text("Export Media")
                        }
                        
                        // MARK: - Import Tags
                        Button("Import Tags", action: self.importTags)
                            // MARK: Import Log Popover
                            .popover(isPresented: .init(get: {
                                self.importLogger != nil
                            }, set: { enabled in
                                if enabled {
                                    if self.importLogger == nil {
                                        self.importLogger = .init()
                                    }
                                } else {
                                    self.importLogger = nil
                                }
                            })) {
                                ImportLogViewer(logger: self.importLogger!)
                            }
                        
                        // MARK: - Export Tags
                        Button("Export Tags", action: self.exportTags)
                    }
                    Section(footer: self.footer()) {
                        // MARK: - Reload Button
                        Button("Reload Media", action: self.reloadMedia)
                        
                        // MARK: - Update Button
                        Button("Update Media", action: self.updateMedia)
                            .disabled(self.updateInProgress)
                        
                        // MARK: - Reset Button
                        Button("Reset Library", action: self.resetLibrary)
                    }
                }
                .navigationTitle("Settings")
                // TODO: Localize Legal
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink("Legal", destination: LegalView())
                    }
                }
            }
            
            .onDisappear {
                if self.languageChanged {
                    AlertHandler.showYesNoAlert(
                        title: NSLocalizedString("Reload library?"),
                        message: NSLocalizedString("Do you want to reload all media objects using the new language?"),
                        yesAction: { _ in self.reloadMedia() }
                    )
                    self.languageChanged = false
                }
            }
        }
    }
    
    // MARK: - Button Functions
    
    func reloadMedia() {
        self.reloadInProgress = true
        
        // Perform the reload in the background on a different thread
        Task {
            print("Starting reload...")
            do {
                // Reload and show the result
                try await self.library.reloadAll()
                await MainActor.run {
                    self.reloadInProgress = false
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Reload Completed"),
                        message: NSLocalizedString("All media objects have been reloaded.")
                    )
                }
            } catch {
                print("Error reloading media objects: \(error)")
                await MainActor.run {
                    self.reloadInProgress = false
                    AlertHandler.showError(title: NSLocalizedString("Error reloading library"), error: error)
                }
            }
        }
    }
    
    func updateMedia() {
        self.updateInProgress = true
        // Execute the update in the background
        Task {
            // We have to handle our errors inside this task manually, otherwise they are simply discarded
            do {
                // Update the available TMDB Languages
                try await Utils.updateTMDBLanguages()
                // Update and show the result
                let updateCount = try await self.library.update()
                
                // Report back the result to the user on the main thread
                await MainActor.run {
                    self.updateInProgress = false
                    let format = NSLocalizedString("%lld media objects have been updated.", tableName: "Plurals")
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Update Completed"),
                        message: String.localizedStringWithFormat(format, updateCount)
                    )
                }
            } catch {
                print("Error updating media objects: \(error)")
                // Update UI on the main thread
                await MainActor.run {
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Update Error"),
                        message: NSLocalizedString("Error updating media objects: \(error.localizedDescription)")
                    )
                    self.updateInProgress = false
                }
            }
        }
    }
    
    // TODO: Refactor
    func importMedia() {
        if !Utils.purchasedPro() {
            if let mediaCount = MediaLibrary.shared.mediaCount() {
                if mediaCount >= JFLiterals.nonProMediaLimit {
                    self.isShowingProInfo = true
                    return
                }
            } else {
                print("Error retrieving media count")
                // continue with import
            }
        }
        // TODO: Exchange logFile with real logger
        // Use iOS file picker
        self.documentPicker = DocumentPicker(onSelect: { url in
            print("Importing \(url.lastPathComponent).")
            self.isLoading = true
            // Document picker finished. Invalidate it.
            self.documentPicker = nil
            
            // Perform the import into a separate context on a background thread
            PersistenceController.shared.container.performBackgroundTask { (importContext: NSManagedObjectContext) in
                // Set the merge policy to not override existing data
                // TODO: Maybe we should?
                importContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
                importContext.name = "Import Context"
                // Initialize the logger
                self.importLogger = .init()
                // Load the CSV data
                do {
                    let csvString = try String(contentsOf: url)
                    print("Read csv file. Trying to import into library.")
                    CSVHelper.importMediaObjects(
                        csvString: csvString,
                        importContext: importContext,
                        onProgress: { progress in
                            // Update the loading view
                            self.loadingText = "Loading \(progress) media objects..."
                        },
                        onFail: { log in
                            importLogger?.log(contentsOf: log, level: .info)
                            importLogger?.critical("Importing failed!")
                            self.importLogShowing = true
                        },
                        onFinish: { mediaObjects, log in
                            importLogger?.log(contentsOf: log, level: .info)
                            // Presenting will change UI
                            DispatchQueue.main.async {
                                // TODO: Tell the user how many duplicates were not added
                                let format = NSLocalizedString("Imported %lld media objects.", tableName: "Plurals")
                                let controller = UIAlertController(
                                    title: NSLocalizedString("Import"),
                                    message: String.localizedStringWithFormat(format, mediaObjects.count),
                                    preferredStyle: .alert
                                )
                                controller.addAction(UIAlertAction(
                                    title: NSLocalizedString("Undo"),
                                    style: .destructive
                                ) { _ in
                                    // Reset all the work we have just done
                                    importContext.reset()
                                    importLogger?.info("Undoing import. All imported objects removed.")
                                    self.importLogShowing = true
                                })
                                controller.addAction(UIAlertAction(
                                    title: NSLocalizedString("Ok"),
                                    style: .default
                                ) { _ in
                                    Task {
                                        // Make the changes to this context permanent by saving them to disk
                                        await PersistenceController.saveContext(importContext)
                                        await MainActor.run {
                                            // TODO: Replace when using real logger
                                            // TODO: Why does this not introduce a race condition? (Modifying the _log Variable)
                                            self.importLogger?.info("Import complete.")
                                            self.importLogShowing = true
                                        }
                                    }
                                })
                                self.isLoading = false
                                // Reset the loading text
                                self.loadingText = nil
                                AlertHandler.presentAlert(alert: controller)
                            }
                        }
                    )
                } catch {
                    print("Error importing: \(error)")
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Import Error"),
                        message: NSLocalizedString("Error importing the media objects: \(error.localizedDescription)")
                    )
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }, onCancel: {
            print("Canceling...")
            self.documentPicker = nil
        })
        #if targetEnvironment(macCatalyst)
        // On macOS present the file picker manually
        UIApplication.shared.windows[0].rootViewController!.present(self.documentPicker!.viewController, animated: true)
        #endif
    }
    
    func exportMedia() {
        // Prepare for export
        print("Exporting...")
        self.isLoading = true
        
        // Perform the export in a separate context on a background thread
        PersistenceController.shared.container.performBackgroundTask { (exportContext: NSManagedObjectContext) in
            exportContext.name = "Export Context"
            let url: URL?
            do {
                let medias = Utils.allMedias(context: self.managedObjectContext)
                let csv = CSVManager.createCSV(from: medias)
                // Save the csv as a file to share it
                url = Utils.documentsPath.appendingPathComponent("MovieDB_Export_\(Utils.isoDateString()).csv")
                try csv.write(to: url!, atomically: true, encoding: .utf8)
            } catch let exception {
                print("Error writing CSV file")
                print(exception)
                self.isLoading = false
                return
            }
            #if targetEnvironment(macCatalyst)
            // Show save file dialog
            self.documentPicker = DocumentPicker(urlToExport: url) { url in
                print("Exporting \(url.lastPathComponent).")
                // Document picker finished. Invalidate it.
                self.documentPicker = nil
                do {
                    // Export the csv to the file
                    try csv.write(to: url, atomically: true, encoding: .utf8)
                } catch let exception {
                    print("Error exporting csv file:")
                    print(exception)
                }
            } onCancel: {
                print("Canceling...")
                self.documentPicker = nil
            }
            // On macOS present the file picker manually
            UIApplication.shared.windows[0].rootViewController!
                .present(self.documentPicker!.viewController, animated: true)
            #else
            Utils.share(items: [url!])
            #endif
            self.isLoading = false
        }
    }
    
    // TODO: Refactor, use async
    func importTags() {
        // Use iOS file picker
        self.documentPicker = DocumentPicker(onSelect: { url in
            print("Importing \(url.lastPathComponent).")
            self.isLoading = true
            // Document picker finished. Invalidate it.
            self.documentPicker = nil
            // TODO: Replace with actor to import the tags
            // TODO: Same for media
            
            DispatchQueue.global().async {
                // Load the CSV data and decode it
                do {
                    let importData = try String(contentsOf: url)
                    print("Imported Tag Export file. Trying to import into library.")
                    // Count the non-empty tags
                    let count = importData.components(separatedBy: "\n").filter({ !$0.isEmpty }).count
                    // Presenting will change UI
                    DispatchQueue.main.async {
                        let format = NSLocalizedString("Do you want to import %lld tags?", tableName: "Plurals")
                        let controller = UIAlertController(
                            title: NSLocalizedString("Import"),
                            message: String.localizedStringWithFormat(format, count),
                            preferredStyle: .alert
                        )
                        controller.addAction(UIAlertAction(
                            title: NSLocalizedString("Yes"),
                            style: .default
                        ) { _ in
                            // Use a background context for importing the tags
                            PersistenceController.shared.container.performBackgroundTask { context in
                                context.name = "Tag Import Context"
                                do {
                                    try TagImporter.import(importData, into: context)
                                    Task {
                                        await PersistenceController.saveContext(context)
                                    }
                                } catch {
                                    print(error)
                                    AlertHandler.showSimpleAlert(
                                        title: NSLocalizedString("Error Importing Tags"),
                                        message: error.localizedDescription
                                    )
                                }
                            }
                        })
                        controller.addAction(UIAlertAction(title: NSLocalizedString("No"), style: .cancel))
                        AlertHandler.presentAlert(alert: controller)
                        self.isLoading = false
                    }
                } catch let error as LocalizedError {
                    print("Error importing: \(error)")
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Import Error"),
                        message: NSLocalizedString("Error Importing the Tags: \(error.localizedDescription)")
                    )
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                } catch let otherError {
                    print("Unknown Error: \(otherError)")
                    assertionFailure("This error should be captured specifically to give the user a more precise " +
                                     "error message.")
                    AlertHandler.showSimpleAlert(
                        title: NSLocalizedString("Import Error"),
                        message: NSLocalizedString("There was an error importing the tags.")
                    )
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }, onCancel: {
            print("Canceling...")
            self.documentPicker = nil
        })
        #if targetEnvironment(macCatalyst)
        // On macOS present the file picker manually
        UIApplication.shared.windows[0].rootViewController!.present(self.documentPicker!.viewController, animated: true)
        #endif
    }
    
    func exportTags() {
        print("Exporting Tags...")
        self.isLoading = true
        
        PersistenceController.shared.container.performBackgroundTask { context in
            context.name = "Tag Export Context"
            var url: URL?
            do {
                let exportData: String = try TagImporter.export(context: context)
                // Save as a file to share it
                url = Utils.documentsPath.appendingPathComponent("MovieDB_Tags_Export_\(Utils.isoDateString()).txt")
                try exportData.write(to: url!, atomically: true, encoding: .utf8)
            } catch let exception {
                print("Error writing Tags Export file")
                print(exception)
                self.isLoading = false
                return
            }
            #if targetEnvironment(macCatalyst)
            // Show save file dialog
            self.documentPicker = DocumentPicker(urlToExport: url) { url in
                print("Exporting \(url.lastPathComponent).")
                // Document picker finished. Invalidate it.
                self.documentPicker = nil
                do {
                    // Export the csv to the file
                    try exportData.write(to: url, atomically: true, encoding: .utf8)
                } catch let exception {
                    print("Error exporting Tag Export file:")
                    print(exception)
                }
            } onCancel: {
                print("Canceling...")
                self.documentPicker = nil
            }
            // On macOS present the file picker manually
            UIApplication.shared.windows[0].rootViewController!
                .present(self.documentPicker!.viewController, animated: true)
            #else
            Utils.share(items: [url!])
            #endif
            self.isLoading = false
        }
    }
    
    func resetLibrary() {
        let controller = UIAlertController(
            title: NSLocalizedString("Reset Library"),
            message: NSLocalizedString("This will delete all media objects in your library. Do you want to continue?"),
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel))
        controller.addAction(UIAlertAction(
            title: NSLocalizedString("Delete"),
            style: .destructive
        ) { _ in
            // Don't reset the tags, only the media objects
            do {
                try self.library.reset()
            } catch let e {
                print("Error resetting media library")
                print(e)
                AlertHandler.showSimpleAlert(
                    title: NSLocalizedString("Error resetting library"),
                    message: e.localizedDescription
                )
            }
        })
        AlertHandler.presentAlert(alert: controller)
    }
    
    func footer() -> some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                ZStack {
                    // Update Progress
                    AnyView(
                        HStack {
                            ActivityIndicator()
                            Text("Updating media library...")
                        }
                    )
                    .hidden(condition: !self.updateInProgress)
                }.frame(height: self.updateInProgress ? nil : 0)
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                Text("Version \(appVersion ?? "unknown")")
            }
            Spacer()
        }
    }
    
    // MARK: - Views
    struct LanguagePickerView: View {
        @ObservedObject var config: JFConfig
        
        var body: some View {
            Picker("Language", selection: $config.language) {
                if config.availableLanguages.isEmpty {
                    Text("Loading...")
                        .task { await self.updateLanguages() }
                } else {
                    ForEach(config.availableLanguages, id: \.self) { code in
                        let languageName = Locale.current.localizedString(forIdentifier: code) ?? code
                        Text(languageName)
                            .tag(code)
                    }
                }
            }
        }
        
        private func updateLanguages() async {
            if config.availableLanguages.isEmpty {
                // Load the TMDB Languages
                do {
                    try await Utils.updateTMDBLanguages()
                } catch {
                    await MainActor.run {
                        print(error)
                        AlertHandler.showSimpleAlert(
                            title: "Error updating languages",
                            message: "There was an error updating the available languages."
                        )
                    }
                }
            }
        }
    }
    
    enum Keys {
        static let showAdults = "showAdults"
    }
    
    struct ImportLogViewer: View {
        let logger: TagImporter.BasicLogger
        
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    Text(logger.log)
                        .lineLimit(nil)
                        .padding()
                        .font(.footnote)
                    Spacer()
                }
                .navigationTitle("Import Log")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Copy") {
                            UIPasteboard.general.string = logger.log
                        }
                    }
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
