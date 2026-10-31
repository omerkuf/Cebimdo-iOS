//
//  View+Keyboard.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
