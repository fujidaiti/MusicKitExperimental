/*
HTTP API一括逆引き実行画面
混合種別対応
*/

import SwiftUI

struct HTTPReverseSearchView: View {
    let selectedItemIDs: [String]
    let searchResults: [MixedSearchResult]
    
    @StateObject private var httpClient = AppleMusicHTTPClient()
    @State private var retrievedItems: [MixedResourceResponse.MixedResourceItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var apiStartTime: Date?
    @State private var apiEndTime: Date?
    
    var responseTime: String {
        guard let start = apiStartTime, let end = apiEndTime else {
            return "-"
        }
        let milliseconds = end.timeIntervalSince(start) * 1000
        return String(format: "%.0f ms", milliseconds)
    }
    
    var itemsByType: [String: [MixedResourceResponse.MixedResourceItem]] {
        Dictionary(grouping: retrievedItems, by: { $0.type })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HTTP API一括逆引き実行")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("要求ID数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(selectedItemIDs.count)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("取得件数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(retrievedItems.count)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(retrievedItems.count == selectedItemIDs.count ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("レスポンス時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(responseTime)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if !isLoading && apiStartTime != nil {
                    HStack {
                        if retrievedItems.count == selectedItemIDs.count {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("全てのIDから正常に取得")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("一部のIDが取得できませんでした")
                                .foregroundColor(.orange)
                        }
                    }
                    .font(.caption)
                }
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("HTTP API実行中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !retrievedItems.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Text("取得結果（種別ごと）")
                            .font(.headline)
                        
                        ForEach(Array(itemsByType.keys).sorted(), id: \.self) { type in
                            if let items = itemsByType[type] {
                                TypeSectionView(type: type, items: items)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else if apiStartTime != nil {
                VStack {
                    Image(systemName: "exclamationmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("該当するアイテムが見つかりませんでした")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Spacer()
            
            if apiStartTime == nil {
                Button("HTTP API実行") {
                    performHTTPReverseSearch()
                }
                .buttonStyle(.prominent)
                .disabled(isLoading)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .navigationTitle("HTTP API逆引き結果")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました")
        }
        .onAppear {
            performHTTPReverseSearch()
        }
    }
    
    private func performHTTPReverseSearch() {
        guard !selectedItemIDs.isEmpty else { 
            print("⚠️ [HTTPReverseSearchView] No items selected for reverse search")
            return 
        }
        
        print("🚀 [HTTPReverseSearchView] Starting HTTP reverse search")
        print("📝 [HTTPReverseSearchView] Selected IDs (\(selectedItemIDs.count)): \(selectedItemIDs)")
        
        isLoading = true
        retrievedItems.removeAll()
        apiStartTime = Date()
        apiEndTime = nil
        
        Task {
            do {
                let response = try await httpClient.fetchMixedResources(ids: selectedItemIDs, searchResults: searchResults)
                
                await MainActor.run {
                    let endTime = Date()
                    self.apiEndTime = endTime
                    self.retrievedItems = response.data
                    self.isLoading = false
                    
                    let responseTimeMs = endTime.timeIntervalSince(self.apiStartTime!) * 1000
                    print("✅ [HTTPReverseSearchView] HTTP API completed successfully")
                    print("⏱️ [HTTPReverseSearchView] Response time: \(String(format: "%.0f", responseTimeMs)) ms")
                    print("📊 [HTTPReverseSearchView] Retrieved \(response.data.count)/\(selectedItemIDs.count) items")
                }
            } catch let error as HTTPAPIError {
                await MainActor.run {
                    let endTime = Date()
                    self.apiEndTime = endTime
                    let responseTimeMs = endTime.timeIntervalSince(self.apiStartTime!) * 1000
                    
                    print("❌ [HTTPReverseSearchView] HTTP API failed with HTTPAPIError")
                    print("⏱️ [HTTPReverseSearchView] Failed after: \(String(format: "%.0f", responseTimeMs)) ms")
                    print("💥 [HTTPReverseSearchView] Error details: \(error)")
                    
                    if case .tokenError(let tokenError) = error {
                        print("🔑 [HTTPReverseSearchView] Token error: \(tokenError)")
                        self.errorMessage = httpClient.getTokenErrorMessage(for: tokenError)
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    
                    self.showError = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let endTime = Date()
                    self.apiEndTime = endTime
                    let responseTimeMs = endTime.timeIntervalSince(self.apiStartTime!) * 1000
                    
                    print("❌ [HTTPReverseSearchView] HTTP API failed with unknown error")
                    print("⏱️ [HTTPReverseSearchView] Failed after: \(String(format: "%.0f", responseTimeMs)) ms")
                    print("💥 [HTTPReverseSearchView] Error: \(error)")
                    
                    self.errorMessage = "HTTP API呼び出しに失敗しました: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct TypeSectionView: View {
    let type: String
    let items: [MixedResourceResponse.MixedResourceItem]
    
    private var typeDisplayName: String {
        switch type {
        case "albums": return "アルバム"
        case "songs": return "楽曲" 
        case "artists": return "アーティスト"
        default: return type
        }
    }
    
    private var typeColor: Color {
        switch type {
        case "albums": return .blue
        case "songs": return .green
        case "artists": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(typeDisplayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                
                Text("\(items.count)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.attributes.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        if let artistName = item.attributes.artistName {
                            Text(artistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("ID: \(item.id)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    if let releaseDate = item.attributes.releaseDate {
                        Text("リリース: \(releaseDate)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
    }
}

struct HTTPReverseSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HTTPReverseSearchView(selectedItemIDs: ["123", "456", "789"], searchResults: [])
        }
    }
}