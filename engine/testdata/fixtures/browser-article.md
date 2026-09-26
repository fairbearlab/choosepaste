# Getting Started with Swift Concurrency

Swift concurrency introduces `async`/`await` as first-class language features, replacing completion handler patterns with structured, readable code.

## Basic async function

```swift
func fetchUser(id: Int) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

## Key concepts

- **async** marks a function that can suspend
- **await** marks a suspension point
- **Task** creates a new unit of asynchronous work
- **Actor** provides data-race safety for mutable state

## Structured concurrency with TaskGroup

For parallel work, use `TaskGroup`:

```swift
func fetchAllUsers(ids: [Int]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask { try await fetchUser(id: id) }
        }
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

See the [official Swift docs](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) for more details.
