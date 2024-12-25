//
//  ContentView.swift
//  pixelApp
//
//  Created by 邱允聰 on 21/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm: HomeVM = HomeVM()
    
    var body: some View {
        NavigationStack{
            ScrollView(.horizontal){
                pixelArt
                    .frame(maxHeight: .infinity, alignment: .center)
                    .ignoresSafeArea()
                    .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItemGroup(placement: .confirmationAction){
                    Button(vm.isSelect ? "Cancel" : "Select") {
                        vm.isSelect.toggle()
                        vm.selectedArt.removeAll()
                    }
                    if !vm.isSelect{
                        NavigationLink {
                            PixelArtScreen(art: PixelArtModel(), homeVM: vm)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    
                }
                if vm.isSelect{
                    ToolbarItem(placement: .cancellationAction){
                        Button(vm.isSelectAll ? "Cancel All" : "Select All", action: { withAnimation{ vm.selectAllArt() } })
                    }
                    ToolbarItem(placement: .status){
                        Text("You selected \(vm.selectedArtNum()) Art")
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("", action: {})
                        Button {
                            vm.isDelete.toggle()
                        } label: {
                            Image(systemName: "trash.fill")
                        }
                    }
                }
            }
        }
        .alert("Delete Art", isPresented: $vm.isDelete, actions: {
            Button("Cancel", action: {vm.isDelete.toggle()})
            Button("Confirm", action: { withAnimation{vm.deleteMultiArt()} })
        }, message: {
            Text("Are you sure to delete the selected art?")
        })
        .onAppear{
            withAnimation {
                vm.getPixelArts()
            }
        }
    }
    
    var pixelArt: some View{
        LazyHStack(spacing: 20){
            ForEach(0..<vm.pixelArts.count, id: \.self){totalNum in
                if vm.searchArt(vm.pixelArts[totalNum].name){
                    if vm.isSelect{
                        VStack{
                            Text(vm.pixelArts[totalNum].name)
                                .font(.title2)
                            PixelScrollView(pixelArray: vm.pixelArts[totalNum].art[0])
                                .overlay {
                                    if vm.isArtSelected(totalNum){
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                            .padding()
                                            .background{
                                                Color.black.opacity(0.5)
                                            }
                                    }
                                }
                        }
                        .onTapGesture {
                            withAnimation{
                                vm.selectArt(totalNum)
                            }
                        }
                    }else{
                        NavigationLink {
                            PixelArtScreen(art: vm.pixelArts[totalNum], homeVM: vm)
                        } label: {
                            VStack{
                                Text(vm.pixelArts[totalNum].name)
                                    .font(.title2)
                                PixelScrollView(pixelArray: vm.pixelArts[totalNum].art[0])
                            }
                        }
                        .contextMenu {
                            Button{
                                vm.selectArt(totalNum)
                                vm.isDelete.toggle()                                
                            }label:{
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $vm.searchText, prompt: "Search art's name")
        .scrollTargetLayout()
    }
}

struct PixelScrollView: View{
    var pixelArray: [[Pixel]]
    
    var body: some View{
        VStack(spacing: 0){
            ForEach(0..<pixelArray.count, id: \.self){i in
                HStack(spacing: 0){
                    ForEach(0..<pixelArray[i].count, id: \.self){j in
                        Rectangle()
                            .fill(pixelArray[i][j].toColor())
                            .border(Color.gray.opacity(0.5))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding(10)
    }
}

#Preview {
    ContentView()
}
