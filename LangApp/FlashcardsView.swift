import SwiftUI
import AVFoundation

struct FlashcardsView: View {
    @EnvironmentObject var viewModel: WordViewModel
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var showingAnswer = false
    @State private var isEditMode = false
    
    var filteredWords: [Word] {
        viewModel.words.filter { viewModel.selectedLevel == "All" || $0.level == viewModel.selectedLevel }
    }
    
    var body: some View {
        VStack {
            levelPicker
            
            ZStack {
                ForEach(filteredWords.indices.reversed(), id: \.self) { index in
                    cardView(for: index)
                }
            }
            .frame(height: 400)
            
            controlButtons
            
            progressIndicator
        }
        .navigationTitle("Flashcards")
        .navigationBarItems(trailing: favoriteButton)
    }
    
    private var levelPicker: some View {
        Picker("Level", selection: $viewModel.selectedLevel) {
            ForEach(viewModel.levels, id: \.self) { level in
                Text(level).tag(level)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private func cardView(for index: Int) -> some View {
        FlashcardView(word: filteredWords[index], showingAnswer: $showingAnswer)
            .stacked(at: index, in: filteredWords.count)
            .offset(x: currentIndex == index ? offset.width : 0, y: 0)
            .rotationEffect(.degrees(Double(offset.width / 5)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { _ in
                        handleSwipe()
                    }
            )
            .onTapGesture {
                withAnimation {
                    showingAnswer.toggle()
                }
            }
    }
    
    private var controlButtons: some View {
        HStack {
            Button(action: previousCard) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .disabled(currentIndex == 0)
            
            Spacer()
            
            Button(action: toggleAnswer) {
                Text(showingAnswer ? "Hide Answer" : "Show Answer")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: nextCard) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .disabled(currentIndex == filteredWords.count - 1)
        }
        .padding()
    }
    
    private var progressIndicator: some View {
        Text("\(currentIndex + 1) / \(filteredWords.count)")
            .font(.caption)
            .padding()
    }
    
    private var favoriteButton: some View {
        Button(action: {
            viewModel.toggleFavorite(for: filteredWords[currentIndex])
        }) {
            Image(systemName: filteredWords[currentIndex].isFavorite ? "star.fill" : "star")
                .foregroundColor(.yellow)
        }
    }
    
    private func handleSwipe() {
        if abs(offset.width) > 100 {
            if offset.width > 0 {
                previousCard()
            } else {
                nextCard()
            }
        }
        offset = .zero
    }
    
    private func nextCard() {
        withAnimation {
            currentIndex = min(currentIndex + 1, filteredWords.count - 1)
            showingAnswer = false
        }
    }
    
    private func previousCard() {
        withAnimation {
            currentIndex = max(currentIndex - 1, 0)
            showingAnswer = false
        }
    }
    
    private func toggleAnswer() {
        withAnimation {
            showingAnswer.toggle()
        }
    }
}

struct FlashcardView: View {
    let word: Word
    @Binding var showingAnswer: Bool
    @State private var isPlayingPronunciation = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
            
            VStack {
                if showingAnswer {
                    Text(word.definition)
                        .font(.title2)
                        .padding()
                    Text(word.turkishMeaning)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding()
                    Text(word.example)
                        .font(.body)
                        .italic()
                        .padding()
                } else {
                    Text(word.term)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Text(word.level)
                    .font(.caption)
                    .padding(5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(5)
                
                Button(action: {
                    speakWord(word.term)
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                        .padding()
                }
                .disabled(isPlayingPronunciation)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
    
    private func speakWord(_ word: String) {
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

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: 0, height: offset * 10))
    }
}

struct FlashcardsView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardsView()
            .environmentObject(WordViewModel())
    }
}
