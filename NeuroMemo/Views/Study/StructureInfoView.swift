// StructureInfoView.swift
import SwiftUI

struct StructureInfoView: View {
    let structure: AnatomicalStructure
    @ObservedObject var viewModel: StudyViewModel
    @State private var showingQuiz = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Imagen de la estructura
                if let imageURL = structure.imageURLs.first {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                }
                
                // Nombre y categoría
                Text(structure.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(structure.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Descripción
                Text("Descripción")
                    .font(.headline)
                
                Text(structure.description)
                    .font(.body)
                
                // Funciones
                if !structure.functions.isEmpty {
                    Text("Funciones")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(structure.functions, id: \.self) { function in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(function)
                        }
                    }
                }
                
                // Relaciones con otras estructuras
                if !structure.relatedStructures.isEmpty {
                    Text("Estructuras relacionadas")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(structure.relatedStructures, id: \.id) { related in
                                VStack {
                                    if let imageURL = related.imageURLs.first {
                                        AsyncImage(url: URL(string: imageURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .foregroundColor(.gray.opacity(0.2))
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                    }
                                    
                                    Text(related.name)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 100)
                                .onTapGesture {
                                    viewModel.selectedStructure = related
                                }
                            }
                        }
                    }
                }
                
                // Botones de acción
                HStack {
                    Button(action: {
                        viewModel.markAsStudied(structure: structure)
                    }) {
                        Text("Marcar como estudiado")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        showingQuiz = true
                    }) {
                        Text("Practicar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Detalles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingQuiz) {
            // Aquí iría el componente de quiz que implementaremos más adelante
            Text("Quiz sobre \(structure.name)")
        }
    }
}
