//
//  ColorArrayModel.swift
//  pixelApp
//
//  Created by 邱允聰 on 12/12/2024.
//

import Foundation
import SwiftUI

struct ColorArray{
    var color: [Color]
    let rainbow: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple]
    
    init(){
        color = [.red, .orange, .yellow, .green, .blue, .indigo, .purple]
    }
}
