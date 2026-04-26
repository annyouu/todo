//
//  ContentView.swift
//  frontend
//
//  Created by KAKUANROU on 2026/04/26.
//

import SwiftUI
import Observation

struct TodoItem: Identifiable, Codable {
    let id: Int
    let title: String
    let done: Bool
}

@Observable
class TodoStore {
    var todos: [TodoItem] = []
    private let baseURL = "http://localhost:8080"

    func fetchTodos() {
        guard let url = URL(string: "\(baseURL)/todos") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data else { return }
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                DispatchQueue.main.async { self.todos = decoded }
            }
        }.resume()
    }

    func addTodo(title: String) {
        guard let url = URL(string: "\(baseURL)/todos") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["title": title])
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            self?.fetchTodos()
        }.resume()
    }

    func deleteTodo(id: Int) {
        guard let url = URL(string: "\(baseURL)/todos/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            self?.fetchTodos()
        }.resume()
    }
}

struct ContentView: View {
    @State private var store = TodoStore()
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("新しいTodo", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("追加") {
                        guard !newTitle.isEmpty else { return }
                        store.addTodo(title: newTitle)
                        newTitle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                List(store.todos) { todo in
                    HStack {
                        Text(todo.title)
                        Spacer()
                        Button("削除") {
                            store.deleteTodo(id: todo.id)
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Todo")
            .onAppear { store.fetchTodos() }
        }
    }
}

#Preview {
    ContentView()
}
