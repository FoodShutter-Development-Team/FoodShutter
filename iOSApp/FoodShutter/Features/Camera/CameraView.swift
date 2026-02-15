//
//  CameraView.swift
//  FoodShutter
//
//  Main camera capture view with photo preview
//

import SwiftUI

struct CameraView: View {
    @StateObject private var camera = CameraManager()
    @State private var showPhotoPreview = false
    @State private var showDetail = false
    @State private var showHistorySidebar = false
    @State private var showSettingsSidebar = false
    @State private var showTrophyHistory = false

    var body: some View {
        ZStack{
            Color.backGround

            if !showPhotoPreview {
                VStack{
                    Spacer()
                        .frame(height: 120)
                    CameraPreview(session: camera.session, camera: camera)
                        .aspectRatio(3/4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(20)
                    Spacer()
                }
                .transition(.identity)
            } else if let image = camera.capturedImage {
                VStack{
                    Spacer()
                        .frame(height: 120)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(20)
                    Spacer()
                }
            } else {
                VStack{
                    Spacer()
                        .frame(height: 120)
                    Text("Error")
                        .foregroundStyle(.red)
                    Spacer()
                }
            }

            VStack {
                Spacer()
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(maxWidth: .infinity)

                Spacer()

                HStack{
                    if showPhotoPreview {
                        HStack{
                            Button("retake",systemImage: "arrow.counterclockwise") {
                                camera.capturedImage = nil
                                withAnimation{
                                    showPhotoPreview = false
                                }
                            }

                            Button("ok",systemImage: "checkmark"){
                                withAnimation{
                                    showDetail = true
                                }
                            }
                            .padding(.leading)
                        }
                        .font(.title2)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                        .padding(10)
                        .glassEffect(.regular.interactive())
                    } else {
                        Button{
                            camera.capturePhoto()
                        } label: {
                            Circle()
                                .glassEffect(.regular.interactive())
                                .tint(.mainEnable)
                        }
                    }
                }
                .frame(width: 80)
                .padding(.top,80)

                Spacer()
            }

            if !showPhotoPreview {
                HStack{
                    HStack{
                        Button{
                            withAnimation(.spring(response: 0.3)) {
                                showHistorySidebar = true
                            }
                        } label: {
                            Image(systemName:"clock")
                        }
                        
                        Button("trophy", systemImage:"trophy") {
                            showTrophyHistory = true
                        }
                        .padding(.leading,10)
                    }
                    .labelStyle(.iconOnly)
                    .padding(10)
                    .glassEffect(.regular.interactive())

                    Spacer()
                    
                    Button("setting", systemImage: "gearshape") {
                        withAnimation(.spring(response: 0.3)) {
                            showSettingsSidebar = true
                        }
                    }
                    .labelStyle(.iconOnly)
                    .padding(10)
                    .glassEffect(.regular.interactive())
                }
                .padding(20)
                .padding(.top,40)
                .font(.title2)
                .foregroundStyle(.black)
                .frame(maxHeight: .infinity,alignment: .top)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showDetail, onDismiss: {
            // Reset to live camera when leaving analysis
            camera.capturedImage = nil
            withAnimation {
                showPhotoPreview = false
            }
        }, content: {
            if let image = camera.capturedImage {
                AnalysisResultView(capturedImage: image)
            }
        })
        .fullScreenCover(isPresented: $showTrophyHistory) {
            TrophyHistoryView()
        }
        .onAppear {
            camera.requestPermission()
        }
        .onChange(of: camera.capturedImage) { _, newImage in
            if newImage != nil {
                withAnimation(){
                    showPhotoPreview = true
                }
            }
        }
        .overlay {
            ZStack {
                // Background - fades in/out
                if showHistorySidebar || showSettingsSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showHistorySidebar = false
                                showSettingsSidebar = false
                            }
                        }
                }

                // History Sidebar - slides from left (animation handled internally)
                HStack {
                    HistorySidebarView(isPresented: $showHistorySidebar)
                    Spacer()
                }

                // Settings Sidebar - slides from right (animation handled internally)
                HStack {
                    Spacer()
                    SettingSidebarView(isPresented: $showSettingsSidebar)
                }
            }
        }

    }
}

#Preview {
    CameraView()
}
