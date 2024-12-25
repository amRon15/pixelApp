//
//  PixelArtModel.swift
//  pixelApp
//
//  Created by 邱允聰 on 21/11/2024.
//

import Foundation
import SwiftUI

struct PixelArtModel: Codable{
    var id: String = UUID().uuidString
    var art: [[[Pixel]]] = [Array(repeating: Array(repeating: Pixel(), count: 16), count: 16)]
    var name: String = "Pixel Art"
}


