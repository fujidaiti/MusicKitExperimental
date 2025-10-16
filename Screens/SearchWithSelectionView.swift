/*
アルバム検索＋複数選択画面
*/

import MusicKit
import SwiftUI

struct SearchWithSelectionView: View {
    @State private var searchTerm = ""
    @State private var albums: MusicItemCollection<Album> = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedAlbums: Set<MusicItemID> = []
    
    var selectedAlbumsArray: [Album] {
        albums.filter { selectedAlbums.contains($0.id) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("アルバム検索")
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
                HStack {
                    Text("検索結果 (\(albums.count)件)")
                        .font(.headline)
                    Spacer()
                    if !selectedAlbums.isEmpty {
                        Text("選択: \(selectedAlbums.count)件")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                List(albums) { album in
                    SelectableAlbumCell(
                        album: album,
                        isSelected: selectedAlbums.contains(album.id)
                    ) { isSelected in
                        if isSelected {
                            selectedAlbums.insert(album.id)
                        } else {
                            selectedAlbums.remove(album.id)
                        }
                    }
                }
                
                if !selectedAlbums.isEmpty {
                    HStack {
                        Spacer()
                        NavigationLink(destination: ReverseSearchView(selectedAlbumIDs: Array(selectedAlbums))) {
                            Text("逆引き実行 (\(selectedAlbums.count)件)")
                                .padding()
                        }
                        .buttonStyle(.prominent)
                        Spacer()
                    }
                }
                
            } else if !isSearching && !searchTerm.isEmpty {
                Text("検索結果がありません")
                    .foregroundColor(.secondary)
                    .italic()
                Spacer()
            } else if searchTerm.isEmpty {
                Text("アルバム名を入力して検索してください")
                    .foregroundColor(.secondary)
                    .italic()
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("ID逆引きAPI検証")
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
        selectedAlbums.removeAll()
        
        Task {
            do {
                // アルバムのみを検索
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

struct SearchWithSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchWithSelectionView()
        }
    }
}