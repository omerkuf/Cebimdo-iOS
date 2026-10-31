//
//  KalanFont.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import SwiftUI

enum KalanFont {

    static let largeTitle = Font.custom(
        "AvenirNext-Bold",
        size: 34,
        relativeTo: .largeTitle
    )

    static let title = Font.custom(
        "AvenirNext-DemiBold",
        size: 26,
        relativeTo: .title
    )

    static let title2 = Font.custom(
        "AvenirNext-DemiBold",
        size: 21,
        relativeTo: .title2
    )

    static let headline = Font.custom(
        "AvenirNext-DemiBold",
        size: 17,
        relativeTo: .headline
    )

    static let body = Font.custom(
        "AvenirNext-Regular",
        size: 16,
        relativeTo: .body
    )

    static let bodyMedium = Font.custom(
        "AvenirNext-Medium",
        size: 16,
        relativeTo: .body
    )

    static let button = Font.custom(
        "AvenirNext-DemiBold",
        size: 16,
        relativeTo: .headline
    )

    static let caption = Font.custom(
        "AvenirNext-Regular",
        size: 12,
        relativeTo: .caption
    )

    static let amount = Font.custom(
        "AvenirNext-Bold",
        size: 21,
        relativeTo: .title2
    )
}
