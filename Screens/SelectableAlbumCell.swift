/*
チェックボックス付きアルバムセル
*/

import MusicKit
import SwiftUI

struct SelectableAlbumCell: View {
    let album: Album
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .primary)
                    
                Text(album.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                if let releaseDate = album.releaseDate {
                    Text(DateFormatter.year.string(from: releaseDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionChanged(!isSelected)
        }
    }
}

extension DateFormatter {
    static let year: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}

struct SelectableAlbumCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // プレビュー用のダミーデータは実際のAlbumオブジェクトが必要なため省略
            Text("SelectableAlbumCell Preview")
                .padding()
        }
    }
}