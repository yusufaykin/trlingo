import SwiftUI

struct ContentView: View {
    @StateObject private var wordViewModel = WordViewModel()
    @State private var userName: String = "Learner"
   
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Welcome, \(userName)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Ready to learn a new language?")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    FeatureButton(title: "Word List", systemImage: "list.bullet", destination: AnyView(WordListView()))
                    FeatureButton(title: "Flashcards", systemImage: "rectangle.on.rectangle", destination: AnyView(FlashcardsView().environmentObject(wordViewModel)))
                    FeatureButton(title: "Quiz", systemImage: "questionmark.circle", destination: AnyView(Text("Quiz View")))
                    FeatureButton(title: "Level Test", systemImage: "chart.bar", destination: AnyView(Text("Level Test View")))
                    FeatureButton(title: "AI Conversation", systemImage: "bubble.left.and.bubble.right", destination: AnyView(Text("AI Conversation View")))
                    
                    Spacer()
                }
            }
            .navigationTitle("Language Learning")
            .navigationBarItems(trailing: Button(action: {
                // Profile action
            }) {
                Image(systemName: "person.circle")
                    .imageScale(.large)
            })
        }
        .environmentObject(wordViewModel)
    }
}


struct FeatureButton: View {
    let title: String
    let systemImage: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordViewModel())
    }
}
