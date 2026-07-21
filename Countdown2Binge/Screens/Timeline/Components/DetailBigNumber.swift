//
//  DetailBigNumber.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailBigNumber: View {
    let value: String
    let isReady: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.custom(.oswald.bold, size: value == "NOW" || value == "TBD" ? 40 : 62))
                .foregroundColor(isReady ? .c2bTealBright : (value == "TBD" ? .c2bMuted : .white))

            if value != "NOW" && value != "TBD" {
                Text("DAYS")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .foregroundColor(.c2bDim)
                    .tracking(2.0)
                    .padding(.top, 4)
            }
        }
    }
}
