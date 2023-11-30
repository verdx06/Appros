import SwiftUI

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

struct Main: View {
    @ObservedObject var pollStore = PollStore()
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(pollStore.polls) { poll in
                    VStack(alignment: .leading) {
                        Text(poll.question)
                            .font(.title)
                        ForEach(poll.options, id: \.self) { option in
                            Button(action: {
                                pollStore.selectOption(poll.question, option: option)
                            }) {
                                Text(option)
                                    .padding(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Polls")
            .navigationBarItems(trailing:
                                    NavigationLink(destination: CreatePollView(pollStore: pollStore)) {
                Text("Create")
            }
            )
        }
    }
}

struct CreatePollView: View {
    @ObservedObject var pollStore: PollStore
    @State private var question = ""
    @State private var option = ""
    @State private var options = [String]()
    
    var body: some View {
        VStack {
            TextField("Enter your question", text: $question)
                .padding()
            HStack {
                TextField("Enter option", text: $option)
                    .padding()
                Button("Add") {
                    options.append(option)
                    option = ""
                }
                .padding()
            }
            List {
                ForEach(options, id: \.self) { option in
                    Text(option)
                }
            }
            Button("Save") {
                pollStore.addPoll(question, options: options)
            }
            Spacer()
            .padding()
        }
        .navigationTitle("Create Poll")
    }
}



#Preview {
    Main()
}
