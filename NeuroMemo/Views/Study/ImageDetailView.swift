import SwiftUI

struct ImageDetailView: View {
    let imageId: UUID
    @StateObject private var viewModel = ImageDetailViewModel()
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingLabels = true
    
    var body: some View {
        ZStack {
            // Fondo
            Color.black
                .ignoresSafeArea()
            
            // Contenido principal
            VStack(spacing: 0) {
                // Información de la imagen
                VStack(alignment: .leading, spacing: 10) {
                    // Título
                    Text(viewModel.image?.title ?? "Imagen anatómica")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Descriptores
                    if let image = viewModel.image {
                        HStack(spacing: 15) {
                            // Modalidad
                            Label(image.modality.rawValue, systemImage: image.modality.iconName)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // Orientación
                            Label(image.orientation.rawValue, systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                // Imagen principal con etiquetas
                GeometryReader { geometry in
                    ZStack {
                        // Imagen
                        if let image = viewModel.displayImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
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
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value
                                            scale = min(max(newScale, 1.0), 5.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        }
                                )
                        }
                        
                        // Etiquetas
                        if showingLabels, let labels = viewModel.image?.labeledStructures {
                            ForEach(labels) { label in
                                LabelMarker(label: label, scale: scale, offset: offset)
                            }
                        }
                    }
                }
                
                // Barra de controles
                HStack(spacing: 20) {
                    // Botón de etiquetas
                    Button(action: {
                        withAnimation {
                            showingLabels.toggle()
                        }
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: showingLabels ? "tag.fill" : "tag")
                                .font(.system(size: 20))
                            
                            Text("Etiquetas")
                                .font(.caption)
                        }
                        .foregroundColor(showingLabels ? .yellow : .gray)
                    }
                    
                    // Botón de mejora
                    Button(action: {
                        viewModel.toggleEnhancement()
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: viewModel.isEnhanced ? "wand.and.stars.inverse" : "wand.and.stars")
                                .font(.system(size: 20))
                            
                            Text("Mejorar")
                                .font(.caption)
                        }
                        .foregroundColor(viewModel.isEnhanced ? .yellow : .gray)
                    }
                    
                    // Botón de modo quiz
                    Button(action: {
                        viewModel.startQuizMode()
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                            
                            Text("Quiz")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
            }
            
            // Indicador de carga
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                viewModel.toggleFavorite()
            }) {
                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                    .foregroundColor(viewModel.isFavorite ? .yellow : .gray)
            }
        )
        .onAppear {
            viewModel.loadImage(id: imageId)
        }
    }
}

// Componente para mostrar etiquetas en la imagen
struct LabelMarker: View {
    let label: LabeledStructure
    let scale: CGFloat
    let offset: CGSize
    
    var body: some View {
        ZStack {
            // Línea desde punto a etiqueta
            Path { path in
                let start = CGPoint(
                    x: label.coordinates.x * scale + offset.width,
                    y: label.coordinates.y * scale + offset.height
                )
                
                let end = CGPoint(
                    x: start.x + 20,
                    y: start.y - 20
                )
                
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Color.white, lineWidth: 1)
            
            // Punto de anclaje
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .position(
                    x: label.coordinates.x * scale + offset.width,
                    y: label.coordinates.y * scale + offset.height
                )
            
            // Etiqueta de texto
            Text(label.name)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.7))
                )
                .position(
                    x: label.coordinates.x * scale + offset.width + 40,
                    y: label.coordinates.y * scale + offset.height - 20
                )
        }
    }
}
