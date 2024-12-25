//
//  pixelArtVM.swift
//  pixelApp
//
//  Created by 邱允聰 on 22/11/2024.
//

import Foundation
import SwiftUI
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers
import Photos

class PixelArtVM: ObservableObject{
    
    @Published var selectedColor: Color = .red
    @Published var colorSelection: Color = .blue
    @Published var colorInt: Int = 0
    @Published var color: ColorArray = ColorArray()
    
    @Published var selectedTool: Tools = .Pencil
    
    @Published var isEditName: Bool = false
    @Published var editingName: String = ""        
    
    @Published var pixelArt: PixelArtModel = PixelArtModel()
    @Published var selectedArtNum: Int = 0
    let emptyPixelArt = Array(repeating: Array(repeating: Pixel(), count: 16), count: 16)
    
    @Published var isSaved: Bool = false
    @Published var savedText: String = ""
    
    @Published var history: [[[Pixel]]] = []
    @Published var currentIndex: Int = 0
    
    @Published var isPreview: Bool = false
    @Published var isPreviewGIF: Bool = false
    @Published var previewGifNum: Int = 0
    @Published var timer: Timer? = nil
    
    init(_ art: PixelArtModel){
        pixelArt = art
        history.append(pixelArt.art[selectedArtNum])
        editingName = art.name
    }
    
    func initPixelArt(_ art: [[[Pixel]]]){
        if !art.isEmpty{
            pixelArt.art = art
        }
    }
    
    func limitNameLength(){
        if pixelArt.name.count > 15{
            pixelArt.name = String(pixelArt.name.prefix(15))
        }
    }
    
    func confirmName(){
        pixelArt.name = editingName
        isEditName.toggle()
    }
    
    func duplicateArt(_ artNum: Int, _ art: [[Pixel]]){
        pixelArt.art.insert(art, at: artNum + 1)
        selectedArtNum = artNum + 1
    }
    
    func deleteArt(_ pixelNum: Int){
        if(pixelArt.art.count > 1){
            //if selected pixel > pixel number, shift it to down by 1
            if selectedArtNum > pixelNum  {
                selectedArtNum -= 1
                
                // If the selected item is being removed, reset selection to a safe default
            } else if selectedArtNum == pixelNum {
                selectedArtNum = max(0, pixelNum - 1)
            }
            
            pixelArt.art.remove(at: pixelNum)
        }
    }
    
    func addArt(){
        pixelArt.art.append(emptyPixelArt)
        changeArt(pixelArt.art.count - 1)
    }
    
    func changeArt(_ pixelNum: Int){
        currentIndex = 0
        selectedArtNum = pixelNum
        history = [pixelArt.art[selectedArtNum]]
    }
    
    
    func changeColor(_ i: Int, _ color: Color){
        selectedColor = color
        colorInt = i
    }
    
    func changeColorPicker(){
        color.color[colorInt] = colorSelection
        selectedColor = colorSelection
    }
        
    func undo(){
        guard currentIndex > 0 else{ return }
        currentIndex -= 1
        pixelArt.art[selectedArtNum] = history[currentIndex]
    }
    
    func redo(){
        if currentIndex < history.count - 1 {
            currentIndex += 1
            pixelArt.art[selectedArtNum] = history[currentIndex]
        }
    }
    
    
    func saveCurrentHistory(){
        let currentState = pixelArt.art[selectedArtNum]
        
        //clear the latest history if action after undo
        while currentIndex < history.count - 1{
            history.removeLast()
        }
        
        //limit 30 times undo
        if history.count > 30{
            history.removeFirst()
            currentIndex -= 1
        }
        
        history.append(currentState)
        currentIndex = history.count - 1
    }
    
    //clear the pixel art
    func clear(){
        pixelArt.art[selectedArtNum] = emptyPixelArt
        saveCurrentHistory()
    }
    
    func fillColor(x: Int, y: Int, color: Color){
        pixelArt.art[selectedArtNum][x][y].setRgb(color)
        saveCurrentHistory()
    }
    
    //save the history once with floodfill
    func floodFillWithSave(x: Int, y: Int){
        floodFill(x: x, y: y, targetColor: pixelArt.art[selectedArtNum][x][y].component)
        saveCurrentHistory()
    }
    
    func floodFill(x: Int, y: Int, targetColor: [CGFloat]){
        //handle left, right, top, bottom edge
        if(x<0 || x>=pixelArt.art[selectedArtNum].count || y<0 || y>=pixelArt.art[selectedArtNum][x].count){
            return
        }
        
        let targetPixelColor = UIColor(selectedColor).cgColor.components
        let currentPixelColor = pixelArt.art[selectedArtNum][x][y].component
        
        //pixel not equal to first target color or already fill same color
        if(currentPixelColor != targetColor || currentPixelColor == targetPixelColor){
            return
        }
        
        //fill color
        pixelArt.art[selectedArtNum][x][y].setRgb(selectedColor)
        
        //recrusive func, check and fill left, right, top, bottom color
        floodFill(x: x + 1, y: y, targetColor: targetColor)
        floodFill(x: x - 1, y: y, targetColor: targetColor)
        floodFill(x: x, y: y + 1, targetColor: targetColor)
        floodFill(x: x, y: y - 1, targetColor: targetColor)
        
        return
    }
        
    //save all the arts in app
    func saveArt(){
        var pixelArts : [PixelArtModel] = []
        
        //get all saved pixel art for a new save
        if let savedData = UserDefaults.standard.data(forKey: "Collection") {
            if let decodedPixelArray = try? JSONDecoder().decode([PixelArtModel].self, from: savedData) {
                pixelArts = decodedPixelArray
            }
        }
        
        //filter out the original pixel art
        var newPixelArts  = pixelArts.filter({$0.id != pixelArt.id})
        newPixelArts.insert(pixelArt, at: 0)
        UserDefaults.standard.set(try? JSONEncoder().encode(newPixelArts), forKey: "Collection")
        
        isSaved.toggle()
        self.savedText = "Pixel Art saved"
    }
    
    //loop through the collection of pixel arts and convert it to uiimage
    @MainActor
    func loopPixelArt() -> [UIImage]{
        var photos : [UIImage] = []
        for pixelNum in 0..<pixelArt.art.count{
            let view = getPixelArtView(pixelArt.art[pixelNum])
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            
            if let image = renderer.uiImage{
                photos.append(image)
            }
        }
        return photos
    }
    
    //export the pixel art as a gif to ablum
    @MainActor
    func exportAsGif(){
        let photos: [UIImage] = loopPixelArt()
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 0.5]] as CFDictionary
        
        let fileURL: URL? = FileManager.default.temporaryDirectory.appendingPathComponent("pixelArtGif.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, UTType.gif.identifier as CFString, photos.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in photos {
                    if let cgImage = image.cgImage {
                        CGImageDestinationAddImage(destination, cgImage, frameProperties)
                    }
                }
                if !CGImageDestinationFinalize(destination) {
                    print("Failed to finalize the image destination")
                }
            }
        }
        
        if (fileURL != nil){
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: fileURL!, options: nil)
                self.isSaved.toggle()
                self.savedText = "GIF saved"
            })
        } else { return }
        
        
    }
    
    //export the pixel art to album
    @MainActor
    func exportArt() {
        let view = getPixelArtView(pixelArt.art[selectedArtNum])
        let renderer = ImageRenderer(
            content: view
        )
        renderer.isOpaque = false
        
        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            isSaved.toggle()
            self.savedText = "JPEG saved"
        }
        
        
    }
    
    //convert pixelArt to transparet background, only show the pixel that with color
    func getPixelArtView(_ pixelArray: [[Pixel]]) -> some View{
        return VStack(spacing: 0){
            ForEach(0..<pixelArray.count, id: \.self){i in
                HStack(spacing: 0){
                    ForEach(0..<pixelArray[i].count, id: \.self){j in
                        GeometryReader{proxy in
                            Rectangle()
                                .fill(pixelArray[i][j].toColor())
                                .frame(width: proxy.size.width, height: proxy.size.width)
                        }
                    }
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }
    
    //preview of pixel art, view pager
    func previewArt() -> some View{
        let view = GeometryReader{proxy in ScrollView(.horizontal){
            LazyHStack(spacing: 0){
                ForEach(0..<self.pixelArt.art.count){i in
                    VStack{
                        self.getPixelArtView(self.pixelArt.art[i])
//                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                        Text("\(i+1)")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(.bottom, 50)
                    }
                }
            }
            .scrollTargetLayout()
        }
            .scrollTargetBehavior(.paging)
            .overlay{
                Button {
                    withAnimation {
                        self.isPreview.toggle()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding()
                .padding(.top, 50)
                .foregroundStyle(.blue)
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background{
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()}
        
        return view
    }
    
    //preview of pixet art, gif like
    func previewArtGIF() -> some View{
        return getPixelArtView(pixelArt.art[previewGifNum])
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay{
                Button {
                    withAnimation {                        
                        self.stopGif()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding()
                .padding(.top, 50)
                .foregroundStyle(.blue)
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background{
                Color.white
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
    }
        
    //call this func when start preview as gif
    func startGif(){
        isPreviewGIF.toggle()
        
        //set the timer to loop the view like a gif
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true){_ in
            //if the number greater than total pixel art it will back to 0
            self.previewGifNum = (self.previewGifNum + 1) % self.pixelArt.art.count
        }
    }
    
    func stopGif(){
        timer?.invalidate()
        timer = nil
        isPreviewGIF.toggle()
    }
}
