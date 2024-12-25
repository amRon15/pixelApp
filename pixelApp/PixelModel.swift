//
//  PixelModel.swift
//  pixelApp
//
//  Created by 邱允聰 on 12/12/2024.
//

import Foundation
import SwiftUI

struct Pixel: Equatable, Codable{
    var component: [CGFloat] = [0,0,0,0] //i'd like to use this to save Color instead of color cuz more easy to handle the persistance
    
    //saving the cgColor components to save it into storage
    mutating func setRgb(_ color: Color){
        if let rgb = UIColor(color).cgColor.components{
            self.component = rgb
        }
    }
    
    //convert the cgFloat array to color 
    func toColor() -> Color{
        Color(red: Double(component[0]), green: Double(component[1]), blue: Double(component[2]), opacity: Double(component.count > 3 ? component[3] : 1.0))
    }
}
