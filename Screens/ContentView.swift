/*
MusicKit API検証アプリのメイン画面
*/

import SwiftUI

struct ContentView: View {
    
    let testItems = [
        TestItem(id: 1, title: "キーワード検索API", description: "MusicCatalogSearchRequestを使用したカタログ検索"),
        TestItem(id: 2, title: "ID逆引きAPI（Album一括）", description: "複数AlbumIDからMusicCatalogResourceRequestで一括取得"),
        TestItem(id: 3, title: "混合種別ID一括逆引きAPI", description: "Apple Music HTTP APIで複数種別（Album/Song/Artist）ID一括取得"),
        TestItem(id: 4, title: "Player キュー操作", description: "ApplicationMusicPlayerのキュー操作とプレイバック制御")
    ]
    
    var body: some View {
        NavigationView {
            List(testItems) { item in
                NavigationLink(destination: destinationView(for: item)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("MusicKit API検証")
        }
        .welcomeSheet()
    }
    
    @ViewBuilder
    private func destinationView(for item: TestItem) -> some View {
        switch item.id {
        case 1:
            SearchTestView()
        case 2:
            SearchWithSelectionView()
        case 3:
            MixedTypeSearchView()
        case 4:
            PlayerQueueTestView()
        default:
            Text("未実装")
        }
    }
}

struct TestItem: Identifiable {
    let id: Int
    let title: String
    let description: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}