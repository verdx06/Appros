import SwiftUI
import CoreImage
import UIKit

struct Poll: Identifiable {
    var id = UUID()
    var question: String
    var options: [String]
}

class PollStore: ObservableObject {
    @Published var polls = [Poll]()
    @Published var selectedOptions = [String: String]()
    
    func addPoll(_ question: String, options: [String]) {
        polls.append(Poll(question: question, options: options))
    }
    
    func selectOption(_ question: String, option: String) {
        selectedOptions[question] = option
    }
}

struct ContentView: View {
    @ObservedObject var pollStore = PollStore()
    @State private var isCreatingPoll = false // Добавляем состояние для отслеживания создания опроса
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Button(action: {
                        isCreatingPoll = true
                    }) {
                        VStack {
                            Image(systemName: "decrease.indent")
                            Text("Create")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .sheet(isPresented: $isCreatingPoll) {
                        CreatePollView(pollStore: pollStore, isCreatingPoll: $isCreatingPoll)
                    }
                    ScrollView {
                        ForEach(pollStore.polls) { poll in
                            VStack(alignment: .leading) {
                                ZStack{
                                    VStack{
                                        Text(poll.question)
                                            .font(.title)
                                        ForEach(poll.options, id: \.self) { option in
                                            Button(action: {
                                                pollStore.selectOption(poll.question, option: option)
                                            }) {
                                                Text(option)
                                                    .padding()
                                                    .foregroundColor(Color.white)
                                                    .background(Color.blue)
                                                    .clipShape(.capsule(style: .continuous))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .border(Color.black, width: 1)
                            .padding(10)
                        }
                    }
                }
                .navigationTitle("Main")
            }
            .tabItem {
                Label("Main", systemImage: "house.fill")
            }
            
            ResultsView(pollStore: pollStore)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            Settings()
                .tabItem {
                    Label("Results", systemImage: "gear")
                }
        }
    }
}

struct CreatePollView: View {
    
    @Environment(\.presentationMode) var presentation
    
    @ObservedObject var pollStore: PollStore
    @State private var question = ""
    @State private var option = ""
    @State private var options = [String]()
    
    @Binding var isCreatingPoll: Bool
    
    var body: some View {
        VStack {
            TextField("Enter your question", text: $question)
                .padding()
            HStack {
                TextField("Enter option", text: $option)
                    .padding()
                Text("\(options.count)")
                Button("Add") {
                    if option != "" && options.count < 10 {
                        options.append(option)
                        option = ""
                    }
                }
                .padding()
            }
            ScrollView {
                ForEach(options, id: \.self) { option in
                    ZStack{
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .foregroundColor(Color.background)
                            .opacity(0.2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(radius: 2)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 40)
                        
                        Button(action: {
                            if let index = options.firstIndex(of: option) {
                                options.remove(at: index)
                            }
                        }, label: {
                            Image(systemName: "multiply")
                        }).frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 30)
                    }
                }
            }
            if options.count >= 2 && !question.isEmpty {
                Button("Save") {
                    pollStore.addPoll(question, options: options)
                    self.presentation.wrappedValue.dismiss()
                    isCreatingPoll = false
                }
                .padding()
            }
        }
        .navigationTitle("Create")
    }
}

struct ResultsView: View {
    @ObservedObject var pollStore: PollStore
    
    var body: some View {
        List {
            Section(header: Text("Voted Polls")) {
                ForEach(pollStore.polls.filter { pollStore.selectedOptions[$0.question] != nil }) { poll in
                    PollRow(pollStore: pollStore, poll: poll)
                }
            }
            
            Section(header: Text("Created Polls")) {
                ForEach(pollStore.polls.filter { pollStore.selectedOptions[$0.question] == nil }) { poll in
                    PollRow(pollStore: pollStore, poll: poll)
                }
            }
        }
    }
}

struct PollRow: View {
    @ObservedObject var pollStore: PollStore
    var poll: Poll
    
    
    @State private var isPresentingShareSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(poll.question)
                if let selectedOption = pollStore.selectedOptions[poll.question] {
                    Text("Selected Option: \(selectedOption)")
                } else {
                    Text("Selected Option: None")
                }
            }
            
            Spacer()
            
            Button(action: {
                isPresentingShareSheet.toggle()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray)
            }
            .sheet(isPresented: $isPresentingShareSheet, onDismiss: {}) {
                generateQRCode()
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    func generateQRCode() -> some View {
        let qrcodeData = Data(poll.question.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(qrcodeData, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    let shareSheetActivityItems = [uiImage]
                    let shareSheet = UIActivityViewController(activityItems: shareSheetActivityItems, applicationActivities: nil)
                    
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        let window = UIWindow(windowScene: scene)
                        window.rootViewController = UIViewController()
                        
                        let hostingController = UIHostingController(rootView: self)
                        window.rootViewController?.addChild(hostingController)
                        window.rootViewController?.view.addSubview(hostingController.view)
                        
                        window.windowLevel = UIWindow.Level.alert + 1
                        window.makeKeyAndVisible()
                        window.rootViewController?.present(shareSheet, animated: true, completion: nil)
                    }
                }
            }
        }
        
        return EmptyView()
    }
}

#Preview {
    ContentView()
}
