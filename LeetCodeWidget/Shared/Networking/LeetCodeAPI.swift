//
//  LeetCodeAPI.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import Foundation

class LeetCodeAPI {
    static let shared = LeetCodeAPI()
    private let baseURL = "https://leetcode.com/graphql"
    
    private init() {}
    
    func fetchStats(username: String? = nil, completion: @escaping (Result<LeetCodeStats, Error>) -> Void) {
        let config = WidgetConfiguration.shared
        let leetCodeUsername = username ?? config.username
        
        guard !leetCodeUsername.isEmpty && leetCodeUsername != "MY_USERNAME_HERE" else {
            completion(.failure(NSError(domain: "LeetCodeAPI", code: -4, userInfo: [NSLocalizedDescriptionKey: "Please configure your LeetCode username in widget settings"])))
            return
        }
        
        let query = """
        {
          matchedUser(username: "\(leetCodeUsername)") {
            submissionCalendar
            submitStats {
              acSubmissionNum {
                difficulty
                count
              }
            }
          }
        }
        """
        
        let requestBody: [String: Any] = [
            "query": query
        ]
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "LeetCodeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LeetCodeAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(LeetCodeResponse.self, from: data)
                if let stats = LeetCodeStats.from(response) {
                    completion(.success(stats))
                } else {
                    completion(.failure(NSError(domain: "LeetCodeAPI", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

