//
//  AddMediaView.swift
//  Movie DB
//
//  Created by Jonas Frey on 26.06.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import struct JFSwiftUI.LoadingView

struct AddMediaView: View {
    @State private var library: MediaLibrary = .shared
    @State private var isShowingProPopup = false
    @State private var isLoading = false
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            NavigationView {
                SearchResultsView { result in
                    Button {
                        Task(priority: .userInitiated) {
                            await self.addMedia(result)
                        }
                    } label: {
                        SearchResultRow(result: result)
                    }
                    .foregroundColor(.primary)
                }
                .navigationTitle(Strings.AddMedia.navBarTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text(Strings.AddMedia.navBarButtonClose)
                }))
            }
        }
        .popover(isPresented: $isShowingProPopup) {
            ProInfoView()
        }
    }
    
    func addMedia(_ result: TMDBSearchResult) async {
        print("Selected \(result.title)")
        // Add the media object to the library
        do {
            try await library.addMedia(result, isLoading: $isLoading)
            // Dismiss the AddMediaView on success
            self.presentationMode.wrappedValue.dismiss()
        } catch UserError.mediaAlreadyAdded {
            await MainActor.run {
                AlertHandler.showSimpleAlert(
                    title: Strings.AddMedia.Alert.alreadyAddedTitle,
                    message: Strings.AddMedia.Alert.alreadyAddedMessage(result.title)
                )
            }
        } catch UserError.noPro {
            // If the user tried to add media without having bought Pro, show the popup
            self.isShowingProPopup = true
        } catch {
            print("Error loading media: \(error)")
            await MainActor.run {
                AlertHandler.showError(
                    title: Strings.AddMedia.Alert.errorLoadingTitle,
                    error: error
                )
                self.isLoading = false
            }
        }
    }
}

struct AddMediaView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .popover(isPresented: .constant(true)) {
                AddMediaView()
            }
    }
}
