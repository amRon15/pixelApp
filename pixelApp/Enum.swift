//
//  Enum.swift
//  pixelApp
//
//  Created by 邱允聰 on 12/12/2024.
//

import Foundation

enum Tools: String, CaseIterable{
    case Pencil = "pencil"
    case Eraser = "eraser.fill"
    case Brush = "paintbrush.fill"
}

enum Edit: String, CaseIterable{
    case Undo = "arrow.uturn.backward"
    case Redo = "arrow.uturn.right"
    case Clear = "clear"
}
