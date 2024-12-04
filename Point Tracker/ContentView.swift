import SwiftUI


struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            PointsView()
        }
    }
}

// Existing PointsView and AddBetView Code
enum BetType: String, Codable {
    case higher = "Higher"
    case lower = "Lower"
}

struct Bet: Identifiable, Codable {
    let id = UUID()
    let title: String
    let amount: Int
    let betType: BetType
}

struct PointsView: View {
    @State private var csaPoints = UserDefaults.standard.integer(forKey: "csaPoints")
    @State private var bets: [Bet] = []
    @State private var showingAddBetView = false
    
    var body: some View {
        VStack {
            // Display CSA Points at the top
            Text("Points: \(csaPoints)")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                // Display the list of bets
                VStack {
                    ForEach(bets) { bet in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bet.title)
                                    .font(.headline)
                                    .foregroundColor(bet.betType == .higher ? .green : .red)
                                Text("Amount: \(bet.amount)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(action: {
                                confirmBet(bet)
                            }) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .padding(.trailing, 10)
                            }
                            Button(action: {
                                deleteBet(bet)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Plus button to add a new bet
            Button(action: {
                showingAddBetView = true
            }) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding()
            }
            .sheet(isPresented: $showingAddBetView) {
                AddBetView { title, amount, betType in
                    addBet(title: title, amount: amount, betType: betType)
                    showingAddBetView = false
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // Load data for points and bets from storage
    private func loadData() {
        csaPoints = UserDefaults.standard.integer(forKey: "csaPoints")
        
        if let savedBets = UserDefaults.standard.data(forKey: "bets") {
            if let decodedBets = try? JSONDecoder().decode([Bet].self, from: savedBets) {
                bets = decodedBets
            }
        }
    }
    
    // Save points and bets to storage
    private func saveData() {
        UserDefaults.standard.set(csaPoints, forKey: "csaPoints")
        
        if let encodedBets = try? JSONEncoder().encode(bets) {
            UserDefaults.standard.set(encodedBets, forKey: "bets")
        }
    }
    
    // Confirm a bet and add points
    private func confirmBet(_ bet: Bet) {
        csaPoints += bet.amount
        deleteBet(bet)
        saveData()
    }
    
    // Delete a bet
    private func deleteBet(_ bet: Bet) {
        bets.removeAll { $0.id == bet.id }
        saveData()
    }
    
    // Add a bet
    private func addBet(title: String, amount: Int, betType: BetType) {
        let newBet = Bet(title: title, amount: amount, betType: betType)
        bets.append(newBet)
        saveData()
    }
}

struct AddBetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedBetType: BetType = .higher
    
    var onSave: (String, Int, BetType) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bet Details")) {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.numberPad)
                    
                    Picker("Bet Type", selection: $selectedBetType) {
                        Text("Higher").tag(BetType.higher)
                        Text("Lower").tag(BetType.lower)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationBarTitle("New Bet", displayMode: .inline)
            .navigationBarItems(trailing: Button("Save") {
                if let amountInt = Int(amount), !title.isEmpty {
                    onSave(title, amountInt, selectedBetType)
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
}
