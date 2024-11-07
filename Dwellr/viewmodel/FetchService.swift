import Foundation
import Amplify
import AWSPluginsCore

enum CustomError: Error {
    case invalidUrl
    case invalidResponse
    case invalidData
}

enum DateError: String, Error {
    case invalidDate
}

let endpoint = "hidden"

func fetch<T : Codable>(body: Encodable?, method: String, endpoint: String, queryItems: [URLQueryItem] = []) async throws -> T {
    
    let session = try await Amplify.Auth.fetchAuthSession() as! AuthCognitoTokensProvider
    let tokens = try session.getCognitoTokens().get()
    let accessToken = tokens.accessToken
    
    guard var url = URL(string: endpoint) else { throw CustomError.invalidUrl  }

    if (!queryItems.isEmpty) {
        if #available(iOS 16.0, *) {
            url.append(queryItems: queryItems)
        } else {
            // Fallback on earlier versions
        }
    }
    
    var urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
    urlRequest.allHTTPHeaderFields = [
        "Content-Type": "application/json",
        "Authorization": accessToken
    ]
    urlRequest.httpMethod = method
    
    if let body = body {
        urlRequest.httpBody = try JSONEncoder().encode(body)
    }
    
    urlRequest.timeoutInterval = 300
    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw CustomError.invalidResponse
    }
    do {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })        
        return try decoder.decode(T.self, from: data)
    } catch let error {
        throw error
    }
}

func createPost(createPostBody: CreatePostBody) async throws -> Post {
    return try await fetch(body: createPostBody, method: "POST", endpoint: "\(endpoint)/api/createPost")
}

func getPosts(offset: Int, limit: Int = 5) async throws -> [Post] {
    return try await fetch(body: nil, method: "GET", endpoint: "\(endpoint)/api/getPosts", queryItems: [URLQueryItem(name: "offset", value: "\(offset)"), URLQueryItem(name: "limit", value: "\(limit)")])
}

func generateDescription(transcript: String) async throws -> PostMetadata {
    return try await fetch(body: GenerateDescriptionBody(transcript: transcript), method: "POST", endpoint: "\(endpoint)/api/describe")
}

func getPresignedUploadUrl() async throws -> PresignResponse {
    return try await fetch(body: nil, method: "GET", endpoint: "\(endpoint)/api/presignedUrl")
}

func uploadToS3(_ fileURL: URL, toPresignedURL remoteURL: URL) async -> Result<URL?, Error> {
    return await withCheckedContinuation { continuation in
        upload(fileURL, toPresignedURL: remoteURL) { (result) in
            switch result {
            case .success(let url):
                print("File uploaded: ", url!)
            case .failure(let error):
                print("Upload failed: ", error.localizedDescription)
            }
            continuation.resume(returning: result)
        }
    }
}

func upload(_ fileURL: URL, toPresignedURL remoteURL: URL, completion: @escaping (Result<URL?, Error>) -> Void) {
    var request = URLRequest(url:  remoteURL )
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.httpMethod = "PUT"
    request.timeoutInterval = 300
    let uploadTask = URLSession.shared.uploadTask(with: request, fromFile: fileURL, completionHandler: { (data, response, error) in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard response != nil, data != nil else {
            completion(.success(nil))
            return
        }
        completion(.success(fileURL))
    })
    uploadTask.resume()
}
