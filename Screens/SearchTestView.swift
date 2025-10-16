/*
キーワード検索APIテスト画面
*/

import MusicKit
import SwiftUI

struct SearchTestView: View {
    @State private var searchTerm = ""
    @State private var albums: MusicItemCollection<Album> = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("検索キーワード")
                    .font(.headline)
                
                HStack {
                    TextField("アルバム名を入力", text: $searchTerm)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("検索") {
                        performSearch()
                    }
                    .buttonStyle(.prominent)
                    .disabled(searchTerm.isEmpty || isSearching)
                }
            }
            
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("検索中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !albums.isEmpty {
                Text("検索結果 (\(albums.count)件)")
                    .font(.headline)
                
                List(albums) { album in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(album.artistName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } else if !isSearching && !searchTerm.isEmpty {
                Text("検索結果がありません")
                    .foregroundColor(.secondary)
                    .italic()
                Spacer()
            } else if searchTerm.isEmpty {
                Text("キーワードを入力して検索してください")
                    .foregroundColor(.secondary)
                    .italic()
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("キーワード検索")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました")
        }
    }
    
    private func performSearch() {
        guard !searchTerm.isEmpty else { return }
        
        isSearching = true
        albums = []
        
        Task {
            do {
                var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                searchRequest.limit = 25
                let searchResponse = try await searchRequest.response()
                
                await MainActor.run {
                    self.albums = searchResponse.albums
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "検索に失敗しました: \(error.localizedDescription)"
                    self.showError = true
                    self.isSearching = false
                }
            }
        }
    }
}

struct SearchTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchTestView()
        }
    }
}