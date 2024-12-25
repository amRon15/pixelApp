//
//  PixelArtScreen.swift
//  pixelApp
//
//  Created by 邱允聰 on 21/11/2024.
//

import SwiftUI

struct PixelArtScreen: View {
    @StateObject var vm: PixelArtVM
    @ObservedObject var homeVm: HomeVM
    @Environment(\.presentationMode) var presentationMode
    
    init(art: PixelArtModel, homeVM: HomeVM){
        _vm = StateObject(wrappedValue: PixelArtVM(art))
        self.homeVm = homeVM
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0){
                pixelArt
                    .border(Color.black, width: 1)
                    .padding(.horizontal, 30)
                    .padding(.top, 70)
                colorPicker
                tools
                pixelList
            }
            .toolbar(vm.isPreview || vm.isPreviewGIF ? .hidden : .visible)
            .toolbar(){
                ToolbarItem(placement: .principal){
                    HStack(spacing: 5){
                        Text("\(vm.pixelArt.name)")
                            .font(.title3)
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        withAnimation {
                            vm.isEditName.toggle()
                        }
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction){
                    Menu{
                        Button {
                            vm.exportArt()
                        } label: {
                            Text("Export as JPEG")
                        }
                        Button {
                            vm.exportAsGif()
                        } label: {
                            Text("Export as GIF")
                        }
                        Button {
                            vm.saveArt()
                        } label: {
                            Text("Save")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                    }
                    Menu {
                        Button("Preview JPEG", action: { withAnimation{vm.isPreview.toggle()} })
                        if vm.pixelArt.art.count > 1{
                            Button("Preview GIF", action:{ withAnimation{vm.startGif()} })
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }

                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.3))
            .ignoresSafeArea()
        }
        .overlay{
            if vm.isPreview{
                vm.previewArt()
            }
            if vm.isPreviewGIF{
                vm.previewArtGIF()                    
            }
        }
        .alert(vm.savedText, isPresented: $vm.isSaved, actions:{
            Button("OK", action: {vm.isSaved.toggle()})
        })
        .alert("Pixel Art Name", isPresented: $vm.isEditName, actions: {
            TextField("Pixel art name", text: $vm.editingName)
                .onChange(of: vm.pixelArt.name){
                    vm.limitNameLength()
                }
                .autocorrectionDisabled()
            
            Button("Cancel", action: {vm.isEditName.toggle()})
            Button("Confirm", action: {vm.confirmName()})
        }, message: {
            Text("You can change the title of your pixel art with maximum 15 character.")
        })
        .onDisappear {
            presentationMode.wrappedValue.dismiss()
            homeVm.getPixelArts()
        }
    }
    
    var pixelArt: some View{
        VStack(spacing: 0){
            ForEach(0..<vm.pixelArt.art[vm.selectedArtNum].count, id: \.self){i in
                HStack(spacing: 0){
                    ForEach(0..<vm.pixelArt.art[vm.selectedArtNum][i].count, id: \.self){j in
                        GeometryReader{proxy in
                            Rectangle()
                                .fill(vm.pixelArt.art[vm.selectedArtNum][i][j].toColor())
                                .border(.gray.opacity(0.5))
                                .frame(width: proxy.size.width, height: proxy.size.width)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation{
                                        switch vm.selectedTool{
                                        case .Pencil: vm.fillColor(x: i, y: j, color: vm.selectedColor)
                                        case .Brush: vm.floodFillWithSave(x: i, y: j)
                                        case .Eraser: vm.fillColor(x: i, y: j, color: .black.opacity(0))
                                        }
                                    }
                                }
                        }
                        .aspectRatio(contentMode: .fit)
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    var colorPicker: some View{
        VStack(spacing: 10){
            HStack(spacing: 10){
                ColorPicker(selection: $vm.colorSelection, label: {})
                    .onChange(of: vm.colorSelection){
                        vm.changeColorPicker()
                    }
                ForEach(Array(vm.color.color.enumerated()), id: \.offset){i, color in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay{
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(vm.selectedColor == color ? AngularGradient(gradient: Gradient(colors: ColorArray().rainbow), center: .center) : AngularGradient(colors: [.white.opacity(0)], center: .center), lineWidth: 3)
                        }
                        .onTapGesture {
                            withAnimation{
                                vm.changeColor(i, color)
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    var tools: some View{
        VStack{
            Grid(horizontalSpacing: 30){
                GridRow{
                    ForEach(Tools.allCases, id: \.self){tool in
                        Image(systemName: tool.rawValue)
                            .font(.title)
                            .frame(width: 80, height: 80)
                            .background{
                                RoundedRectangle(cornerRadius: 10).fill(vm.selectedTool == tool ? Color.cyan : Color.white)
                            }
                            .foregroundStyle(vm.selectedTool == tool ? .white : .gray)
                            .onTapGesture {
                                vm.selectedTool = tool
                            }
                    }
                }
                GridRow{
                    ForEach(Edit.allCases, id: \.self){edit in
                        Button{
                            switch edit{
                            case .Undo:
                                vm.undo()
                            case .Redo:
                                vm.redo()
                            case .Clear:
                                vm.clear()
                            }
                        } label: {
                            Image(systemName: edit.rawValue)
                                .font(.title)
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .animation(.default, value: vm.selectedTool)
        .padding(.horizontal)
    }
    
    //loop all pixel art, at the bottom
    var pixelArtPreview: some View{
        ForEach(Array(vm.pixelArt.art.enumerated()), id: \.offset){pixelNum, pixelArt in
            VStack(spacing: 0){
                ForEach(Array(pixelArt.enumerated()), id: \.offset){i, pixelI in
                    HStack(spacing: 0){
                        ForEach(Array(pixelI.enumerated()), id: \.offset){j, pixelJ in
                            Rectangle()
                                .fill(pixelJ.toColor())
                                .border(.gray.opacity(0.5))
                                .frame(width: 7, height: 7)
                        }
                    }
                }
            }
            .overlay{
                Grid{
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                withAnimation{
                                    vm.duplicateArt(pixelNum, pixelArt)
                                }
                            }
                        Spacer()
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .onTapGesture{
                                withAnimation{
                                    vm.deleteArt(pixelNum)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(pixelNum == vm.selectedArtNum ? 1 : 0)
                        .frame(maxHeight: .infinity, alignment: .center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(pixelNum == vm.selectedArtNum ? Color.black.opacity(0.6) : nil)
            }
            .onTapGesture{
                withAnimation{
                    vm.changeArt(pixelNum)
                }
            }
        }
    }
    
    //bottom pixel list
    var pixelList: some View{
        ScrollView(.horizontal) {
            ScrollViewReader{proxy in
                HStack(spacing: 30){
                    pixelArtPreview
                    Button {
                        withAnimation{
                            vm.addArt()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                    }
                    Spacer()
                        .id(vm.pixelArt.art.count)
                }
                .padding(.bottom, 10)
                .onChange(of: vm.pixelArt.art.count + 1, initial: false){e, _  in
                    withAnimation{
                        proxy.scrollTo(e, anchor: .trailing)
                    }
                }
            }
        }
        .padding(.horizontal, 50)
        .scrollIndicators(.never)
    }
}

#Preview {
    PixelArtScreen(art: PixelArtModel(), homeVM: HomeVM())
}
