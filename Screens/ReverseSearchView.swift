/*
ID一括逆引き実行画面
*/

import MusicKit
import SwiftUI

struct ReverseSearchView: View {
    let selectedAlbumIDs: [MusicItemID]
    
    @State private var retrievedAlbums: MusicItemCollection<Album> = []
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ID逆引き実行")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("要求ID数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(selectedAlbumIDs.count)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("取得件数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(retrievedAlbums.count)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(retrievedAlbums.count == selectedAlbumIDs.count ? .green : .orange)
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
                        if retrievedAlbums.count == selectedAlbumIDs.count {
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
                    Text("ID逆引き実行中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !retrievedAlbums.isEmpty {
                Text("取得結果")
                    .font(.headline)
                
                List(Array(retrievedAlbums), id: \.id) { album in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(album.artistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("ID: \(album.id.rawValue)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        if let releaseDate = album.releaseDate {
                            Text("リリース: \(DateFormatter.yearMonthDay.string(from: releaseDate))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else if apiStartTime != nil {
                VStack {
                    Image(systemName: "exclamationmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("該当するアルバムが見つかりませんでした")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Spacer()
            
            if apiStartTime == nil {
                Button("逆引き実行") {
                    performReverseSearch()
                }
                .buttonStyle(.prominent)
                .disabled(isLoading)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .navigationTitle("ID逆引き結果")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました")
        }
        .onAppear {
            performReverseSearch()
        }
    }
    
    private func performReverseSearch() {
        guard !selectedAlbumIDs.isEmpty else { return }
        
        isLoading = true
        retrievedAlbums = []
        apiStartTime = Date()
        apiEndTime = nil
        
        Task {
            do {
                let albumsRequest = MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: selectedAlbumIDs)
                let albumsResponse = try await albumsRequest.response()
                
                await MainActor.run {
                    self.apiEndTime = Date()
                    self.retrievedAlbums = albumsResponse.items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.apiEndTime = Date()
                    self.errorMessage = "ID逆引きに失敗しました: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

extension DateFormatter {
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

struct ReverseSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReverseSearchView(selectedAlbumIDs: [])
        }
    }
}