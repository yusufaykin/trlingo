import SwiftUI
import AVFoundation

struct Word: Identifiable, Codable {
    let id = UUID()
    let term: String
    let definition: String
    let turkishMeaning: String
    let example: String
    let level: String
    var isFavorite: Bool = false
    var isInPersonalDictionary: Bool = false
}

class WordViewModel: ObservableObject {
    @Published var words: [Word]
    @Published var selectedLevel = "All"
    @Published var personalDictionary: [Word] = []
    
    let levels = ["All", "A1", "A2", "B1", "B2", "C1", "C2"]
    
    init() {
        self.words = [
            Word(term: "Apple", definition: "A round fruit with red or green skin and white flesh", turkishMeaning: "Elma", example: "I eat an apple every day.", level: "A1"),
            Word(term: "Book", definition: "A set of printed or written pages bound together", turkishMeaning: "Kitap", example: "She loves reading books.", level: "A1"),
            Word(term: "Computer", definition: "An electronic device for storing and processing data", turkishMeaning: "Bilgisayar", example: "I use my computer for work.", level: "A2"),
            Word(term: "Democracy", definition: "A system of government by the whole population or all eligible members of a state", turkishMeaning: "Demokrasi", example: "The country is moving towards democracy.", level: "B1"),
            Word(term: "Euphoria", definition: "A feeling or state of intense excitement and happiness", turkishMeaning: "Coşku", example: "The team was in a state of euphoria after winning the championship.", level: "C1")
        ]
        loadPersonalDictionary()
    }
    
    func toggleFavorite(for word: Word) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].isFavorite.toggle()
        }
        if let index = personalDictionary.firstIndex(where: { $0.id == word.id }) {
            personalDictionary[index].isFavorite.toggle()
        }
        savePersonalDictionary()
    }
    
    func togglePersonalDictionary(for word: Word) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].isInPersonalDictionary.toggle()
            if words[index].isInPersonalDictionary {
                personalDictionary.append(words[index])
            } else {
                personalDictionary.removeAll { $0.id == word.id }
            }
            savePersonalDictionary()
        }
    }
    
    private func savePersonalDictionary() {
        if let encoded = try? JSONEncoder().encode(personalDictionary) {
            UserDefaults.standard.set(encoded, forKey: "PersonalDictionary")
        }
    }
    
    private func loadPersonalDictionary() {
        if let savedItems = UserDefaults.standard.data(forKey: "PersonalDictionary"),
           let decodedItems = try? JSONDecoder().decode([Word].self, from: savedItems) {
            personalDictionary = decodedItems
            for word in personalDictionary {
                if let index = words.firstIndex(where: { $0.id == word.id }) {
                    words[index].isInPersonalDictionary = true
                    words[index].isFavorite = word.isFavorite
                }
            }
        }
    }
}

struct WordListView: View {
    @StateObject private var viewModel = WordViewModel()
    @State private var selectedWord: Word?
    @State private var showingFavoritesOnly = false
    @State private var showingPersonalDictionary = false
    @State private var searchText = ""
    
    var filteredWords: [Word] {
        let wordsToFilter = showingPersonalDictionary ? viewModel.personalDictionary : viewModel.words
        return wordsToFilter.filter { word in
            (viewModel.selectedLevel == "All" || word.level == viewModel.selectedLevel) &&
            (!showingFavoritesOnly || word.isFavorite) &&
            (searchText.isEmpty || word.term.lowercased().contains(searchText.lowercased()))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text(showingPersonalDictionary ? "Personal Dictionary" : "Word List")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { showingFavoritesOnly.toggle() }) {
                        Image(systemName: showingFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    Button(action: { showingPersonalDictionary.toggle() }) {
                        Image(systemName: "book")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                
                SearchBar(text: $searchText)
                
                Picker("Level", selection: $viewModel.selectedLevel) {
                    ForEach(viewModel.levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.white)
                
                List {
                    ForEach(filteredWords) { word in
                        WordRow(word: word, toggleFavorite: { viewModel.toggleFavorite(for: word) })
                            .onTapGesture {
                                selectedWord = word
                            }
                            .listRowBackground(Color.white.opacity(0.8))
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.gray.opacity(0.1))
            }
            .background(Color.gray.opacity(0.1))
            .sheet(item: $selectedWord) { word in
                WordDetailView(word: word, viewModel: viewModel)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct WordRow: View {
    let word: Word
    let toggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(word.term)
                    .font(.headline)
                Text(word.definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(word.turkishMeaning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: toggleFavorite) {
                Image(systemName: word.isFavorite ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WordDetailView: View {
    let word: Word
    @ObservedObject var viewModel: WordViewModel
    @State private var isPlayingPronunciation = false
    @State private var showingQuiz = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: "https://source.unsplash.com/featured/?{\(word.term)}")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 5)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                HStack {
                    Text(word.term)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { viewModel.toggleFavorite(for: word) }) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title)
                    }
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(title: "Turkish Meaning", content: word.turkishMeaning)
                    DetailRow(title: "Definition", content: word.definition)
                    DetailRow(title: "Example", content: word.example)
                    DetailRow(title: "Level", content: word.level)
                }
                
                Button(action: {
                    speakWord(word.term)
                }) {
                    Label(isPlayingPronunciation ? "Playing..." : "Listen to Pronunciation", systemImage: "speaker.wave.2")
                }
                .buttonStyle(BorderedButtonStyle())
                .padding(.top)
                .disabled(isPlayingPronunciation)
                
                Button(action: {
                    viewModel.togglePersonalDictionary(for: word)
                }) {
                    Label(word.isInPersonalDictionary ? "Remove from Personal Dictionary" : "Add to Personal Dictionary", systemImage: word.isInPersonalDictionary ? "minus" : "plus")
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button(action: {
                    showingQuiz = true
                }) {
                    Label("Take a Quiz", systemImage: "questionmark.circle")
                }
                .buttonStyle(BorderedButtonStyle())
                .sheet(isPresented: $showingQuiz) {
                    QuizView(word: word)
                }
            }
            .padding()
        }
        .navigationTitle(word.term)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func speakWord(_ word: String) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        
        isPlayingPronunciation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPlayingPronunciation = false
        }
    }
}

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(content)
                .font(.body)
        }
    }
}

struct QuizView: View {
    let word: Word
    @State private var userAnswer = ""
    @State private var showingResult = false
    @State private var isCorrect = false
    @State private var quizType = 0 // 0: Turkish, 1: Definition, 2: Example
    
    var body: some View {
        VStack(spacing: 20) {
            Text(quizPrompt)
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text(word.term)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Check Answer") {
                checkAnswer()
            }
            .buttonStyle(BorderedButtonStyle())
            
            if showingResult {
                Text(isCorrect ? "Correct!" : "Incorrect. Try again!")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title2)
                
                if !isCorrect {
                    Text("Correct answer: \(correctAnswer)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Next Question") {
                nextQuestion()
            }
            .buttonStyle(BorderedButtonStyle())
            .padding(.top)
        }
        .padding()
    }
    
    var quizPrompt: String {
        switch quizType {
        case 0:
            return "What's the Turkish meaning of this word?"
        case 1:
            return "What's the definition of this word?"
        case 2:
            return "Complete the example sentence:"
        default:
            return ""
        }
    }
    
    var correctAnswer: String {
        switch quizType {
        case 0:
            return word.turkishMeaning
        case 1:
            return word.definition
        case 2:
            return word.example
        default:
            return ""
        }
    }
    
    func checkAnswer() {
        isCorrect = userAnswer.lowercased() == correctAnswer.lowercased()
        showingResult = true
    }
    
    func nextQuestion() {
        userAnswer = ""
        showingResult = false
        quizType = (quizType + 1) % 3
    }
}

struct WordListView_Previews: PreviewProvider {
    static var previews: some View {
        WordListView()
    }
}
