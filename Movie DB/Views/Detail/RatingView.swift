//
//  RatingView.swift
//  Movie DB
//
//  Created by Jonas Frey on 23.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI

/// Provides a view that displays an editable star rating
struct RatingView: View {
    
    @Binding var rating: Int
    @Environment(\.editMode) private var editMode
    // TODO: Implement editing
    
    var body: some View {
        // Valid ratings are 0 to 10 stars (0 to 5 stars)
        Group {
            if editMode?.wrappedValue.isEditing ?? false {
                self.starString(rating)
                    .padding(.vertical, 5)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged({ (value) in
                        print("Location: \(value.location)")
                    }))
            } else {
                self.starString(rating)
                    .padding(.vertical, 5)
            }
        }
    }
    
    private func starString(_ rating: Int) -> some View {
        guard 0...10 ~= rating else {
            return starString(0)
        }
        return HStack {
            ForEach(0..<(rating / 2)) { _ in
                Image(systemName: "star.fill")
            }
            if rating % 2 == 1 {
                Image(systemName: "star.lefthalf.fill")
            }
            // Only if there is at least one empty star
            if rating < 9 {
                ForEach(0..<(10 - rating) / 2) { _ in
                    Image(systemName: "star")
                }
            }
        }
    }
}

struct RatingView_Previews: PreviewProvider {
    static var previews: some View {
        RatingView(rating: .constant(5))
    }
}
