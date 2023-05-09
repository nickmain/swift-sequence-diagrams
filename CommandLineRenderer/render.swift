// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@main
struct Renderer {
    static func main() async throws {
        let renderer = ImageRenderer(content:
            ZStack {
                Rectangle().fill(.white)
                ContentView()
            }
            .environment(\.colorScheme, .light)
            .frame(width: 800, height: 800))

        if let image = renderer.cgImage {
            let fileURL = URL(fileURLWithPath: "/Users/nickmain/Desktop/foo.png")
            if let dest = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
            }
        }
    }
}
