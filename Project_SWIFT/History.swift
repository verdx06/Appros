//
//  History.swift
//  Project_SWIFT
//
//  Created by Виталий Багаутдинов on 26.11.2023.
//

import SwiftUI

struct History: View {
    @ObservedObject var pollStore: PollStore
    var body: some View {
        List {
            VStack {
                ForEach(pollStore.polls) { poll in
                    Text("Вопрос: \(poll.question)")
                    
                    
                    Text("\(pollStore.selectedOptions[poll.question] ?? "None")")
                }
            }
        }
    }
}

#Preview {
    History(pollStore: PollStore())
}
