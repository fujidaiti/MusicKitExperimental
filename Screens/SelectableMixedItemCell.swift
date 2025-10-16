/*
チェックボックス付き混合種別アイテムセル
Album/Song/Artist対応
*/

import SwiftUI

struct SelectableMixedItemCell: View {
    let item: MixedSearchResult
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
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .primary)
                    
                Text(item.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(item.type.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeBackgroundColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    
                    Text("ID: \(item.id)")
                        .font(.system(.caption2, design: .monospaced))
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
    
    private var typeBackgroundColor: Color {
        switch item.type {
        case .albums:
            return .blue
        case .songs:
            return .green
        case .artists:
            return .orange
        }
    }
}

struct SelectableMixedItemCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            Text("SelectableMixedItemCell Preview")
                .padding()
            Text("Preview requires MusicKit objects which cannot be created directly")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}