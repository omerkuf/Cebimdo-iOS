//
//  SplashView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import SwiftUI
import Lottie

struct SplashView: View {
    @State private var visibleLetters = 0
    private let letters = Array("Cebimdo")

    var body: some View {
        VStack {
            LottieView(animation: .named("KalanSplash"))
                .playing(
                    .fromProgress(
                        0,
                        toProgress: 1,
                        loopMode: .playOnce
                    )
                )
                .frame(width: 180, height: 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color("LaunchBackground")
                .ignoresSafeArea()
        )
    }
}

