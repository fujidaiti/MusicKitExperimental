/*
混合種別検索画面
Album/Song/Artist の横断検索と選択
*/

import MusicKit
import SwiftUI

enum MixedItemType: String, CaseIterable {
    case albums = "albums"
    case songs = "songs" 
    case artists = "artists"
    
    var displayName: String {
        switch self {
        case .albums: return "アルバム"
        case .songs: return "楽曲"
        case .artists: return "アーティスト"
        }
    }
}

struct MixedSearchResult: Identifiable {
    let id: String
    let name: String
    let artistName: String
    let type: MixedItemType
    let musicItemID: MusicItemID?
    
    init(from album: Album) {
        self.id = album.id.rawValue
        self.name = album.title
        self.artistName = album.artistName
        self.type = .albums
        self.musicItemID = album.id
    }
    
    init(from song: Song) {
        self.id = song.id.rawValue
        self.name = song.title
        self.artistName = song.artistName
        self.type = .songs
        self.musicItemID = song.id
    }
    
    init(from artist: Artist) {
        self.id = artist.id.rawValue
        self.name = artist.name
        self.artistName = artist.name
        self.type = .artists
        self.musicItemID = artist.id
    }
}

struct MixedTypeSearchView: View {
    @State private var searchTerm = ""
    @State private var searchResults: [MixedSearchResult] = []
    @State private var selectedItems: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    TextField("キーワード検索", text: $searchTerm)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("検索") {
                        performSearch()
                    }
                    .buttonStyle(.prominent)
                    .disabled(searchTerm.isEmpty || isLoading)
                }
                
                HStack {
                    Text("選択中: \(selectedItems.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !selectedItems.isEmpty {
                        Button("クリア") {
                            selectedItems.removeAll()
                        }
                        .font(.caption)
                    }
                }
            }
            .padding()
            
            Divider()
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("検索中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else if searchResults.isEmpty && !searchTerm.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("検索結果なし")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchResults.isEmpty {
                List(searchResults) { result in
                    SelectableMixedItemCell(
                        item: result,
                        isSelected: selectedItems.contains(result.id),
                        onSelectionChanged: { isSelected in
                            if isSelected {
                                selectedItems.insert(result.id)
                            } else {
                                selectedItems.remove(result.id)
                            }
                        }
                    )
                }
            } else {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("キーワードを入力して検索してください")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if !selectedItems.isEmpty {
                VStack(spacing: 8) {
                    Divider()
                    
                    NavigationLink(
                        destination: HTTPReverseSearchView(
                            selectedItemIDs: Array(selectedItems), 
                            searchResults: searchResults
                        )
                    ) {
                        HStack {
                            Text("HTTP API で一括逆引き実行")
                            Spacer()
                            Text("\(selectedItems.count)件")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.prominent)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("混合種別検索")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました")
        }
    }
    
    private func performSearch() {
        guard !searchTerm.isEmpty else { 
            print("⚠️ [MixedTypeSearchView] Empty search term")
            return 
        }
        
        print("🔍 [MixedTypeSearchView] Starting search for: '\(searchTerm)'")
        
        isLoading = true
        searchResults.removeAll()
        
        Task {
            do {
                // 1回のAPIコールで全種別を取得
                var searchRequest = MusicCatalogSearchRequest(
                    term: searchTerm, 
                    types: [Album.self, Song.self, Artist.self]
                )
                searchRequest.limit = 10
                
                print("📡 [MixedTypeSearchView] Sending MusicKit search request...")
                let searchResponse = try await searchRequest.response()
                
                var allResults: [MixedSearchResult] = []
                
                // Albums
                let albumResults = searchResponse.albums.map { MixedSearchResult(from: $0) }
                allResults.append(contentsOf: albumResults)
                print("🎵 [MixedTypeSearchView] Found \(albumResults.count) albums")
                
                // Songs
                let songResults = searchResponse.songs.map { MixedSearchResult(from: $0) }
                allResults.append(contentsOf: songResults)
                print("🎶 [MixedTypeSearchView] Found \(songResults.count) songs")
                
                // Artists
                let artistResults = searchResponse.artists.map { MixedSearchResult(from: $0) }
                allResults.append(contentsOf: artistResults)
                print("👤 [MixedTypeSearchView] Found \(artistResults.count) artists")
                
                await MainActor.run {
                    self.searchResults = allResults
                    self.isLoading = false
                    print("✅ [MixedTypeSearchView] Search completed with \(allResults.count) total results")
                }
                
            } catch {
                print("❌ [MixedTypeSearchView] Search failed: \(error)")
                await MainActor.run {
                    self.errorMessage = "検索に失敗しました: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct MixedTypeSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MixedTypeSearchView()
        }
    }
}