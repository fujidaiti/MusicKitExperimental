//
//  SharedContentHandler.swift
//  MusicAlbums
//
//  Created by Daichi Fujita on 2025/08/12.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
class SharedContentHandler {

    static private let appGroup: String =
        "group.dev.norelease.musickit-tutorial.group"

    static private let listenLaterQueueKey: String = "listenLaterQueue"

    enum Result {
        case failure(String)
        case succes
    }

    private(set) var result: Result?

    func handleSharedItem(_ sharedItem: NSExtensionItem) async -> Bool {
        // Ensure access to extensionItem and itemProvider
        guard
            let itemProvider = sharedItem.attachments?.first
        else {
            result = .failure("No content are shared")
            return false
        }

        guard
            itemProvider.hasItemConformingToTypeIdentifier(
                UTType.url.identifier
            )
        else {
            result = .failure("Item is not of type \(UTType.url.identifier)")
            return false
        }

        var loadedItem: NSSecureCoding
        do {
            loadedItem = try await itemProvider.loadItem(
                forTypeIdentifier: UTType.url.identifier,
                options: nil
            )
        } catch {
            result = .failure("\(error)")
            return false
        }

        guard let url = loadedItem as? URL else {
            result = .failure("Unexpected type: \(loadedItem)")
            return false
        }

        // Append the shapred url to the queue.
        // The containing app sees this queue and processes the urls in it.
        let userDefaults = UserDefaults(suiteName: Self.appGroup)
        if var listenLaterQueue = userDefaults?.array(
            forKey: Self.listenLaterQueueKey
        ) {
            listenLaterQueue.append(url.absoluteString)
            userDefaults?.set(
                listenLaterQueue,
                forKey: Self.listenLaterQueueKey
            )
        } else {
            userDefaults?.set(
                [url.absoluteString],
                forKey: Self.listenLaterQueueKey
            )
        }

        result = .succes
        return true

    }
}
