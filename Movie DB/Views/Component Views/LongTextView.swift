//
//  LongTextView.swift
//  Movie DB
//
//  Created by Jonas Frey on 08.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI

/// Represents a view that displays a preview of a longer text with the option to show the full text in a new view
struct LongTextView: View {
    var headline: Text
    var text: String
    
    var body: some View {
            NavigationLink(destination: preview) {
                Text(text)
                    .lineLimit(3)
            }
    }
    
    private var preview: some View {
        VStack(alignment: .center) {
            Text(text)
                .lineLimit(nil)
                .padding()
            Spacer()
        }
        .navigationTitle(headline)
    }
    
    /// Creates a new view that displays a preview of the given text (3 lines).
    /// Provides the option to show the full text in a new view.
    /// - Parameters:
    ///   - headline: The headline of the new full text view
    ///   - text: The full text
    init(
        _ text: String,
        headline: Text
    ) {
        self.headline = headline
        self.text = text
    }
}

struct LongTextView_Previews: PreviewProvider {
    static var previews: some View {
        LongTextView("A very long text", headline: Text(verbatim: "Description"))
    }
}
