/*
Apple Music HTTP API クライアント
DeveloperToken管理とHTTPリクエスト処理
*/

import Foundation
import MusicKit

enum HTTPAPIError: Error {
    case tokenError(MusicTokenRequestError)
    case networkError(URLError)
    case apiError(statusCode: Int, message: String)
    case decodingError(Error)
    case invalidURL
    case noDataReceived
    
    var localizedDescription: String {
        switch self {
        case .tokenError(let musicError):
            return "トークンエラー: \(musicError.localizedDescription)"
        case .networkError(let urlError):
            return "ネットワークエラー: \(urlError.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "APIエラー (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "データ解析エラー: \(error.localizedDescription)"
        case .invalidURL:
            return "無効なURL"
        case .noDataReceived:
            return "データが受信されませんでした"
        }
    }
}

struct MixedResourceResponse: Codable {
    let data: [MixedResourceItem]
    
    struct MixedResourceItem: Codable, Identifiable {
        let id: String
        let type: String
        let attributes: MixedResourceAttributes
        
        struct MixedResourceAttributes: Codable {
            let name: String
            let artistName: String?
            let releaseDate: String?
            let artwork: Artwork?
            let trackCount: Int?
            let genreNames: [String]?
            
            struct Artwork: Codable {
                let width: Int?
                let height: Int?
                let url: String?
            }
        }
    }
}

@MainActor
class AppleMusicHTTPClient: ObservableObject {
    private let tokenProvider = DefaultMusicTokenProvider()
    private var cachedToken: String?
    private var tokenExpiration: Date?
    private let session = URLSession.shared
    
    private func getDeveloperToken() async throws -> String {
        if let cachedToken = cachedToken,
           let expiration = tokenExpiration,
           Date() < expiration {
            print("🔑 [AppleMusicHTTPClient] Using cached developer token")
            return cachedToken
        }
        
        print("🔑 [AppleMusicHTTPClient] Requesting new developer token...")
        
        do {
            let token = try await tokenProvider.developerToken(options: [])
            self.cachedToken = token
            self.tokenExpiration = Date().addingTimeInterval(3600) // 1時間後
            print("🔑 [AppleMusicHTTPClient] Developer token obtained successfully")
            return token
        } catch let error as MusicTokenRequestError {
            print("❌ [AppleMusicHTTPClient] Developer token request failed: \(error)")
            throw HTTPAPIError.tokenError(error)
        } catch {
            print("❌ [AppleMusicHTTPClient] Unknown error getting developer token: \(error)")
            throw HTTPAPIError.tokenError(.unknown)
        }
    }
    
    func fetchMixedResources(ids: [String], searchResults: [MixedSearchResult]) async throws -> MixedResourceResponse {
        print("🚀 [AppleMusicHTTPClient] Starting HTTP API request")
        print("📝 [AppleMusicHTTPClient] IDs to fetch: \(ids)")
        
        let token = try await getDeveloperToken()
        
        guard let storefront = try? await MusicDataRequest.currentCountryCode else {
            print("❌ [AppleMusicHTTPClient] Failed to get storefront")
            throw HTTPAPIError.apiError(statusCode: 0, message: "ストアフロントの取得に失敗しました")
        }
        
        print("🌍 [AppleMusicHTTPClient] Storefront: \(storefront)")
        
        // IDsを種別ごとに分類
        let idsByType = Dictionary(grouping: searchResults.filter { ids.contains($0.id) }) { $0.type }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/catalog/\(storefront)"
        
        var queryItems: [URLQueryItem] = []
        
        // 種別ごとにIDsを設定
        if let albumItems = idsByType[.albums], !albumItems.isEmpty {
            let albumIds = albumItems.map { $0.id }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "ids[albums]", value: albumIds))
            print("🎵 [AppleMusicHTTPClient] Album IDs: \(albumIds)")
        }
        
        if let songItems = idsByType[.songs], !songItems.isEmpty {
            let songIds = songItems.map { $0.id }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "ids[songs]", value: songIds))
            print("🎶 [AppleMusicHTTPClient] Song IDs: \(songIds)")
        }
        
        if let artistItems = idsByType[.artists], !artistItems.isEmpty {
            let artistIds = artistItems.map { $0.id }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "ids[artists]", value: artistIds))
            print("👤 [AppleMusicHTTPClient] Artist IDs: \(artistIds)")
        }
        
        // includeパラメータを追加
        queryItems.append(URLQueryItem(name: "include", value: "artists,albums"))
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("❌ [AppleMusicHTTPClient] Invalid URL construction")
            throw HTTPAPIError.invalidURL
        }
        
        print("🔗 [AppleMusicHTTPClient] API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📤 [AppleMusicHTTPClient] Sending HTTP request...")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [AppleMusicHTTPClient] No HTTP response received")
                throw HTTPAPIError.noDataReceived
            }
            
            print("📡 [AppleMusicHTTPClient] HTTP Status: \(httpResponse.statusCode)")
            print("📊 [AppleMusicHTTPClient] Response data size: \(data.count) bytes")
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                print("❌ [AppleMusicHTTPClient] API Error (\(httpResponse.statusCode)): \(errorMessage)")
                throw HTTPAPIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            do {
                let mixedResponse = try JSONDecoder().decode(MixedResourceResponse.self, from: data)
                print("✅ [AppleMusicHTTPClient] Successfully decoded \(mixedResponse.data.count) items")
                
                // 種別ごとのカウントを表示
                let countByType = Dictionary(grouping: mixedResponse.data, by: { $0.type })
                for (type, items) in countByType {
                    print("📈 [AppleMusicHTTPClient] \(type): \(items.count) items")
                }
                
                return mixedResponse
            } catch {
                print("❌ [AppleMusicHTTPClient] JSON decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [AppleMusicHTTPClient] Response JSON: \(jsonString)")
                }
                throw HTTPAPIError.decodingError(error)
            }
            
        } catch let error as URLError {
            print("❌ [AppleMusicHTTPClient] Network error: \(error)")
            throw HTTPAPIError.networkError(error)
        } catch let httpError as HTTPAPIError {
            throw httpError
        } catch {
            print("❌ [AppleMusicHTTPClient] Unknown error: \(error)")
            throw HTTPAPIError.apiError(statusCode: 0, message: "不明なエラー: \(error.localizedDescription)")
        }
    }
    
    func getTokenErrorMessage(for error: MusicTokenRequestError) -> String {
        switch error {
        case .developerTokenRequestFailed:
            return "Developer Token の取得に失敗しました。\nApp ID と MusicKit サービスの設定を確認してください。"
        case .permissionDenied:
            return "Apple Music へのアクセス許可が拒否されました。\n設定から許可を与えてください。"
        case .privacyAcknowledgementRequired:
            return "最新のプライバシーポリシーへの同意が必要です。\nApple Music アプリで同意してください。"
        case .userNotSignedIn:
            return "Apple ID にサインインしていません。\n設定からサインインしてください。"
        case .userTokenRequestFailed:
            return "ユーザートークンの取得に失敗しました。"
        case .userTokenRevoked:
            return "Apple Music へのアクセス許可が取り消されました。\n再度許可を与えてください。"
        case .unknown:
            return "不明なエラーが発生しました。"
        @unknown default:
            return "予期しないエラーが発生しました。"
        }
    }
}