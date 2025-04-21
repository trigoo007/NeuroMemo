// AnatomicalImageView.swift
import SwiftUI

struct AnatomicalImageView: View {
    let image: AnatomicalImage
    @ObservedObject var viewModel: ImageProcessingViewModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedLabel: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Imagen base
                Image(uiImage: image.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnitude
                                scale = min(max(newScale, 1.0), 5.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                    lastScale = 1.0
                                    lastOffset = .zero
                                }
                            }
                    )
                
                // Etiquetas
                ForEach(image.labels, id: \.id) { label in
                    let position = calculatePosition(for: label, in: geometry.size)
                    
                    ZStack {
                        Circle()
                            .fill(selectedLabel == label.text ? Color.blue : Color.red)
                            .frame(width: 12, height: 12)
                        
                        if selectedLabel == label.text {
                            Text(label.text)
                                .font(.caption)
                                .padding(6)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 2)
                                .offset(y: -20)
                        }
                    }
                    .position(position)
                    .scaleEffect(scale)
                    .offset(offset)
                    .onTapGesture {
                        withAnimation {
                            if selectedLabel == label.text {
                                selectedLabel = nil
                            } else {
                                selectedLabel = label.text
                                viewModel.selectStructure(withName: label.text)
                            }
                        }
                    }
                }
            }
        }
        .clipped()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.toggleLabelsVisibility()
                }) {
                    Image(systemName: viewModel.showAllLabels ? "tag.fill" : "tag")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Activar reconocimiento de voz
                    viewModel.startVoiceRecognition()
                }) {
                    Image(systemName: "mic.fill")
                }
            }
        }
    }
    
    private func calculatePosition(for label: AnatomicalImage.Label, in size: CGSize) -> CGPoint {
        let imageWidth = size.width
        let imageHeight = size.width * (image.image.size.height / image.image.size.width)
        
        return CGPoint(
            x: imageWidth * label.position.x,
            y: imageHeight * label.position.y
        )
    }
}
