//
//  ImportExportSection.swift
//  Movie DB
//
//  Created by Jonas Frey on 23.04.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

struct ImportExportSection: View {
    @State private var importLogger: TagImporter.BasicLogger?
    @State private var importLogShowing = false
    @State private var documentPicker: DocumentPicker?
    @Binding var config: SettingsViewConfig
    
    private var documentPickerPresented: Binding<Bool> {
        .init {
            documentPicker != nil
        } set: { newState in
            if !newState {
                self.documentPicker = nil
            }
        }
    }
    
    @Environment(\.managedObjectContext) private var managedObjectContext: NSManagedObjectContext
    
    var body: some View {
        Section {
            // MARK: - Import Button
            Button(Strings.Settings.importMediaLabel, action: self.importMedia)
            
            // MARK: - Export Button
            Button(Strings.Settings.exportMediaLabel, action: self.exportMedia)
            
            // MARK: - Import Tags
            Button(Strings.Settings.importTagsLabel, action: self.importTags)
                // MARK: Import Log Popover
                .popover(isPresented: $importLogShowing) {
                    if let logger = importLogger {
                        ImportLogViewer(logger: logger)
                    } else {
                        EmptyView()
                    }
                }
            
            // MARK: - Export Tags
            Button(Strings.Settings.exportTagsLabel, action: self.exportTags)
                .popover(item: self.$documentPicker, content: { $0 })
        }
    }
    
    func importMedia() {
        if !Utils.purchasedPro() {
            let mediaCount = MediaLibrary.shared.mediaCount() ?? 0
            guard mediaCount < JFLiterals.nonProMediaLimit else {
                self.config.isShowingProInfo = true
                return
            }
        }
        self.import { importContext, url in
            // Parse the CSV data
            let csvString = try String(contentsOf: url)
            print("Read csv file. Trying to import into library.")
            CSVHelper.importMediaObjects(
                csvString: csvString,
                importContext: importContext,
                onProgress: { progress in
                    // Update the loading view
                    self.config.loadingText = Strings.Settings.loadingTextMediaImport(progress)
                }, onFail: { log in
                    importLogger?.log(contentsOf: log, level: .info)
                    importLogger?.critical("Importing failed!")
                    self.importLogShowing = true
                }, onFinish: { mediaObjects, log in
                    importLogger?.log(contentsOf: log, level: .info)
                    // Presenting will change UI
                    Task(priority: .userInitiated) {
                        await MainActor.run {
                            let controller = UIAlertController(
                                title: Strings.Settings.Alert.importMediaConfirmTitle,
                                message: Strings.Settings.Alert.importMediaConfirmMessage(mediaObjects.count),
                                preferredStyle: .alert
                            )
                            controller.addAction(UIAlertAction(
                                title: Strings.Settings.Alert.importMediaConfirmButtonUndo,
                                style: .destructive
                            ) { _ in
                                // Reset all the work we have just done
                                importContext.reset()
                                importLogger?.info("Undoing import. All imported objects removed.")
                                self.importLogShowing = true
                            })
                            controller.addAction(.okayAction { _ in
                                Task(priority: .userInitiated) {
                                    // Make the changes to this context permanent by saving them to the
                                    // main context and then to disk
                                    await PersistenceController.saveContext(importContext)
                                    await PersistenceController.saveContext(PersistenceController.viewContext)
                                    await MainActor.run {
                                        // TODO: Why does this not introduce a race condition? (Modifying the _log Variable)
                                        self.importLogger?.info("Import complete.")
                                        self.importLogShowing = true
                                    }
                                }
                            })
                            self.config.isLoading = false
                            // Reset the loading text
                            self.config.loadingText = nil
                            AlertHandler.presentAlert(alert: controller)
                        }
                    }
                }
            )
        }
    }
    
    func exportMedia() {
        export(filename: "MovieDB_Export_\(Utils.isoDateString()).csv") { context in
            let medias = Utils.allMedias(context: context)
            return CSVManager.createCSV(from: medias)
        }
    }
    
    func importTags() {
        self.import { importContext, url in
            let importData = try String(contentsOf: url)
            print("Imported Tag Export file. Trying to import into library.")
            // Count the non-empty tags
            let count = importData.components(separatedBy: "\n").filter({ !$0.isEmpty }).count
            
            // Ask whether the user really wants to import
            Task(priority: .userInitiated) {
                await MainActor.run {
                    let controller = UIAlertController(
                        title: Strings.Settings.Alert.importTagsConfirmTitle,
                        message: Strings.Settings.Alert.importTagsConfirmMessage(count),
                        preferredStyle: .alert
                    )
                    controller.addAction(.yesAction { _ in
                        Task(priority: .userInitiated) {
                            // TODO: Duplicate error handling. Would prefer to rethrow the error, but we are in a Task
                            // Use the background context for importing the tags
                            do {
                                try await TagImporter.import(importData, into: importContext)
                                await PersistenceController.saveContext(importContext)
                            } catch {
                                print(error)
                                AlertHandler.showError(
                                    title: Strings.Settings.Alert.importTagsErrorTitle,
                                    error: error
                                )
                            }
                        }
                    })
                    controller.addAction(.noAction())
                    AlertHandler.presentAlert(alert: controller)
                    self.config.isLoading = false
                }
            }
        }
    }
    
    func exportTags() {
        export(filename: "MovieDB_Tags_Export_\(Utils.isoDateString()).txt") { context in
            try TagImporter.export(context: context)
        }
    }
    
    // Does not save the imported changes!
    func `import`(_ handler: @escaping (NSManagedObjectContext, URL) throws -> Void) {
        // Use iOS file picker
        self.documentPicker = DocumentPicker(onSelect: { url in
            print("Importing \(url.lastPathComponent).")
            self.config.isLoading = true
            // Document picker finished. Invalidate it.
            self.documentPicker = nil
            
            // Perform the import into a separate context on a background thread
            PersistenceController.shared.container.performBackgroundTask { (importContext: NSManagedObjectContext) in
                // Set the merge policy to not override existing data
                importContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
                importContext.name = "\(url.lastPathComponent) Import Context"
                // Initialize the logger
                self.importLogger = .init()
                do {
                    try handler(importContext, url)
                } catch let error {
                    print("Error importing: \(error)")
                    AlertHandler.showError(
                        title: Strings.Settings.Alert.genericImportErrorTitle,
                        error: error
                    )
                    Task(priority: .userInitiated) {
                        await MainActor.run {
                            self.config.isLoading = false
                        }
                    }
                }
            }
        }, onCancel: {
            print("Canceling...")
            self.documentPicker = nil
        })
    }
    
    func export(filename: String, content: @escaping (NSManagedObjectContext) throws -> String) {
        print("Exporting \(filename)...")
        self.config.isLoading = true
        
        Task(priority: .userInitiated) {
            await PersistenceController.shared.container.performBackgroundTask { context in
                context.name = "\(filename) Export Context"
                do {
                    // Get the content to export
                    let exportData: String = try content(context)
                    // Save as a file to share it
                    guard let url = Utils.documentsPath?.appendingPathComponent(filename) else {
                        Task(priority: .userInitiated) {
                            await MainActor.run {
                                AlertHandler.showSimpleAlert(
                                    title: Strings.Settings.Alert.genericExportErrorTitle,
                                    message: Strings.Settings.Alert.genericExportErrorMessage
                                )
                            }
                        }
                        return
                    }
                    try exportData.write(to: url, atomically: true, encoding: .utf8)
                    Utils.share(items: [url])
                } catch {
                    print("Error writing Export file")
                    print(error)
                    // Stop the loading animation
                    Task(priority: .userInitiated) {
                        await MainActor.run {
                            self.config.isLoading = false
                        }
                    }
                    return
                }
                Task(priority: .userInitiated) {
                    await MainActor.run {
                        self.config.isLoading = false
                    }
                }
            }
        }
    }
}

struct ImportExportSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ImportExportSection(config: .constant(SettingsViewConfig()))
        }
    }
}
