#  HTTPClient

A simple client for making HTTP requests.  It provides a set of components for simplifying making networking requests:

* Static helper on `HTTPClient` for making requests
* Instance based `HTTPClient` for making requests with a specified `URLSession`, `URLSessionConfiguration`, or resolution queue
* Instance based `APIClient` for making requests against a specific host with varying results by path

Loading a `JSON` request with the static helper and codable types

```swift
struct StackResponse: Codable {
    let items: [StackItem]
    let has_more: Bool
    let quota_max: Int
    let quota_remaining: Int
}

struct StackItem: Codable {
    let tags: [String]
    let owner: StackUser
    let is_answered: Bool
    let view_count: Int
    let answer_count: Int
    let score: Int
    let last_activity_date: Int64
    let creation_date: Int64
    let question_id: Int64
    let link: String
    let title: String
}

struct StackUser: Codable {
    let reputation: Int
    let user_id: Int64
    let user_type: String
    let profile_image: String
    let display_name: String
    let link: String
}

let stackURL = URL(string: "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&tagged=swift&site=stackoverflow")!
HTTPClient.get(stackURL).then { (result: StackResponse) in
    debugPrint(result)
}.catch { error in
    debugPrint("Failed to load stack results: \(error)")
}
```

Loading a `JSON` request with the `APIClient` and codable types overriding `JSON` keys
```swift

struct StackResponseCorrected: Codable {
    let items: [StackItemCorrected]
    let hasMore: Bool
    let quotaMax: Int
    let quotaRemaining: Int

    enum CodingKeys: String, CodingKey {
        case items = "items"
        case hasMore = "has_more"
        case quotaMax = "quota_max"
        case quotaRemaining = "quota_remaining"
    }
}

struct StackItemCorrected: Codable {
    let tags: [String]
    let owner: StackUserCorrected
    let isAnswered: Bool
    let viewCount: Int
    let answerCount: Int
    let score: Int
    let lastActivityDate: Int64
    let creationDate: Int64
    let questionID: Int64
    let link: String
    let title: String

    enum CodingKeys: String, CodingKey {
        case tags = "tags"
        case owner = "owner"
        case isAnswered = "is_answered"
        case viewCount = "view_count"
        case answerCount = "answer_count"
        case score = "score"
        case lastActivityDate = "last_activity_date"
        case creationDate = "creation_date"
        case questionID = "question_id"
        case link = "link"
        case title = "title"
    }
}

struct StackUserCorrected: Codable {
    let reputation: Int?
    let userID: Int64?
    let userType: String?
    let profileImage: String?
    let displayName: String
    let link: String?

    enum CodingKeys: String, CodingKey {
        case reputation = "reputation"
        case userID = "user_id"
        case userType = "user_type"
        case profileImage = "profile_image"
        case displayName = "display_name"
        case link = "link"
    }
}

let queryItems = [
    URLQueryItem(name: "order", value: "desc"),
    URLQueryItem(name: "sort", value: "activity"),
    URLQueryItem(name: "tagged", value: "swift"),
    URLQueryItem(name: "site", value: "stackoverflow")
]

try! stackAPIClient.get("/2.2/search", queryItems: queryItems).then { (result: StackResponse) in
    debugPrint(result)
}.catch { error in
    debugPrint("Failed to load stack results: \(error)")
}

try! stackAPIClient.get("/2.2/search", queryItems: queryItems).then { (result: StackResponseCorrected) in
    debugPrint(result)
}.catch { error in
    debugPrint("Failed to load corrected stack result: \(error)")
    guard let decodingError = error as? HTTPClient.HTTPClientError else { return }
    switch decodingError {
        case .decodingFailed(let type, let data):
        debugPrint("Failed to decode \(type) from \(String(bytes: data, encoding: .utf8)!)")
    default:
    break;
}
```
