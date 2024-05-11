//
//  ContentView.swift
//  testanimation
//
//  Created by Daniel Jesus Callisaya Hidalgo on 20/4/24.
//
import SwiftUI
import Combine

// Constantes de tiempo
let fadeInTime: Double = 2
let fadeOutTime: Double = 2
let totalDisplayTime: Double = 10
let stableTime: Double = totalDisplayTime - fadeInTime - fadeOutTime  // 6 segundos

// MARK: - Enum para manejar los estados de la animación
enum AnimationState: String, CaseIterable {
    case fadeIn = "Fade In"
    case stable = "Stable"
    case fadeOut = "Fade Out"

    // Función para moverse al siguiente estado
    func next() -> AnimationState {
        switch self {
        case .fadeIn:
            return .stable
        case .stable:
            return .fadeOut
        case .fadeOut:
            return .fadeIn
        }
    }
}

// MARK: - DataObject
struct SymbolDO: Identifiable {
    let id = UUID()
    var name: String
    var description: String
}

// MARK: - ObservableObject
class SymbolsOO: ObservableObject {
    @Published var currentSymbol: SymbolDO?
    @Published var symbolOpacity: Double = 0.0
    @Published var symbolScale: CGFloat = 0.2
    @Published var symbolColor: Color = .black
    @Published var currentState = AnimationState.fadeIn
    @Published var timeElapsed: Double = 0
    
    private var symbols: [SymbolDO] = [
        SymbolDO(name: "person.fill", description: "Person"),
        SymbolDO(name: "airplane", description: "Airplane"),
        SymbolDO(name: "house.fill", description: "House"),
        SymbolDO(name: "car.fill", description: "Car"),
        SymbolDO(name: "flame.fill", description: "Flame"),
        SymbolDO(name: "pencil", description: "Pencil"),
    ]
    
    private var currentIndex = 0
    private var timer: Timer?
    private var displayTimer: Timer?
    
    // Inicializar y comenzar la animación
    func startAnimatingSymbols() {
        moveToNextSymbol()
        scheduleDisplayTimer()
    }
    
    private func moveToNextSymbol() {
        currentSymbol = symbols[currentIndex % symbols.count]
        currentIndex += 1
        currentState = .fadeIn
        symbolOpacity = 0.0
        symbolScale = 0.2
        symbolColor = .black
        timeElapsed = 0
        animateSymbol()
    }
    
    private func animateSymbol() {
        // Cancelar cualquier timer existente para evitar sobreposiciones
        timer?.invalidate()
        
        switch currentState {
        case .fadeIn:
            withAnimation(.easeIn(duration: fadeInTime)) {
                self.symbolOpacity = 1.0
                self.symbolScale = 1.0
            }
        case .stable:
            changeColorEvery(interval: stableTime / 3, times: 3)
        case .fadeOut:
            withAnimation(.easeOut(duration: fadeOutTime)) {
                self.symbolOpacity = 0.0
                self.symbolScale = 0.2
            }
        }
        
        // Programar el siguiente cambio de estado
        timer = Timer.scheduledTimer(withTimeInterval: currentState == .stable ? stableTime : (currentState == .fadeIn ? fadeInTime : fadeOutTime), repeats: false) { [weak self] _ in
            self?.advanceState()
        }
    }
    
    private func advanceState() {
        currentState = currentState.next()
        if currentState == .fadeIn {
            if currentIndex >= symbols.count {
                currentIndex = 0
            }
            moveToNextSymbol()  // Inicia un nuevo ciclo con el siguiente símbolo
        } else {
            animateSymbol()
        }
    }
    
    private func changeColorEvery(interval: Double, times: Int) {
        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation {
                    self.symbolColor = Color(red: Double.random(in: 0...1),
                                             green: Double.random(in: 0...1),
                                             blue: Double.random(in: 0...1))
                }
            }
        }
    }
    
    private func scheduleDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeElapsed += 0.1
            if self.timeElapsed >= totalDisplayTime {
                self.timeElapsed = 0
            }
        }
    }
}

// MARK: - View
struct SymbolsView: View {
    @StateObject private var oo = SymbolsOO()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Time: \(String(format: "%.1f", oo.timeElapsed))s")
                        .bold()
                    Text("State: \(oo.currentState.rawValue)")
                        .bold()
                }
                .padding()
            }
            Spacer()
            if let symbol = oo.currentSymbol {
                Image(systemName: symbol.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(oo.symbolColor)
                    .opacity(oo.symbolOpacity)
                    .scaleEffect(oo.symbolScale)
                    .padding()
                Text(symbol.description)
                    .font(.title)
                Text("Description: \(symbol.description)")
                    .font(.body)
            } else {
                Text("No Symbol")
            }
            Spacer()
        }
        .onAppear {
            oo.startAnimatingSymbols()
        }
    }
}


#Preview {
    SymbolsView()
}
