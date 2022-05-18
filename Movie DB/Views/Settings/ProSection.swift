//
//  ProSection.swift
//  Movie DB
//
//  Created by Jonas Frey on 23.04.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import Foundation
import SwiftUI

struct ProSection: View {
    @Binding var config: SettingsViewConfig
    
    var body: some View {
        Section {
            Button(String(
                localized: "settings.actions.buyPro.label",
                comment: "The label for the button in the settings to buy the pro version of the app"
            ), action: { self.config.isShowingProInfo = true })
            .popover(isPresented: $config.isShowingProInfo) {
                ProInfoView()
            }
        }
    }
}

struct ProSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProSection(config: .constant(SettingsViewConfig()))
        }
    }
}
