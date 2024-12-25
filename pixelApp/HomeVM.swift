//
//  HomeVM.swift
//  pixelApp
//
//  Created by 邱允聰 on 12/12/2024.
//

import Foundation

class HomeVM: ObservableObject{
    @Published var pixelArts: [PixelArtModel] = []
    @Published var refresh: Bool = false
    
    @Published var isSelect: Bool = false
    @Published var isSelectAll: Bool = false
    @Published var isDelete: Bool = false
    @Published var selectedArt: [Int: PixelArtModel] = [:]
    
    @Published var searchText: String = ""
    
    func getPixelArts(){
        if let savedData = UserDefaults.standard.data(forKey: "Collection") {
            if let decodedPixelArray = try? JSONDecoder().decode([PixelArtModel].self, from: savedData) {
                pixelArts = decodedPixelArray
            }
        }
    }
    
    func deletePixelArt(_ id: String){
        pixelArts = pixelArts.filter { $0.id != id }
        UserDefaults.standard.set(try? JSONEncoder().encode(pixelArts), forKey: "Collection")
    }
    
    func searchArt(_ name: String) -> Bool{
        return name.lowercased().contains(searchText.lowercased()) || searchText == ""
    }
    
    func isArtSelected(_ pixelNum: Int) -> Bool{
        return selectedArt[pixelNum] != nil
    }
    
    //toggle the selection of pixel art when click
    func selectArt(_ pixelNum: Int){
        if selectedArt[pixelNum] != nil{
            selectedArt.removeValue(forKey: pixelNum)
        }else{
            selectedArt[pixelNum] = pixelArts[pixelNum]
        }
    }
    
    func selectAllArt(){
        isSelectAll.toggle()
        if isSelectAll{
            for i in 0..<pixelArts.count{
                selectedArt[i] = pixelArts[i]
            }
        }else{
            selectedArt.removeAll()
        }
    }
    
    func selectedArtNum() -> Int{
        return selectedArt.count
    }
    
    func deleteMultiArt(){
        var newPixelArt: [PixelArtModel] = []
        //            newPixelArt = pixelArts.filter{ $0.id != selectedArt[selectedArt.keys.enumerated()]?.id}
        for (i, e) in pixelArts.enumerated(){
            if e.id != selectedArt[i]?.id{
                newPixelArt.append(e)
            }
        }
        pixelArts = newPixelArt
        UserDefaults.standard.set(try? JSONEncoder().encode(newPixelArt), forKey: "Collection")
        isSelect = false
        isDelete = false
        isSelectAll = false
    }        
}
