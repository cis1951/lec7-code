//
//  GameView.swift
//  Guesstaurant
//
//  Created by the CIS 1951 team on 2/25/24.
//

import SwiftUI

struct GameView: View {
    @StateObject var viewModel = GameViewModel()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 32) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading...")
                            .bigText()
                    }
                case .error:
                    VStack(spacing: 32) {
                        Text("Oh no! There was an error.")
                            .bigText()
                        Button("Retry") {
                            viewModel.loadGame()
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                    }
                case .ready:
                    Text("Place device on forehead")
                        .bigText()
                case .restaurant(let mapItem):
                    Text(mapItem.name ?? "Unknown Restaurant")
                        .bigText()
                case .correct:
                    Text("Correct")
                        .bigText()
                case .pass:
                    Text("Pass")
                        .bigText()
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if viewModel.state.showsScore {
                Text("\(viewModel.score)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(viewModel.state.background, ignoresSafeAreaEdges: .all)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadGame()
        }
    }
}

#Preview {
    GameView()
}
