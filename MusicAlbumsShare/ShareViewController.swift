//
//  ShareViewController.swift
//  MusicAlbumsShare
//
//  Created by Daichi Fujita on 2025/08/11.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    static private let appGroup: String =
        "group.dev.norelease.musickit-tutorial.group"
    static private let listenLaterQueueKey: String = "listenLaterQueue"

    private var contentView: UIHostingController<ShareView>?

    override func loadView() {
        super.loadView()
        // host the SwiftU view
        let contentView = UIHostingController(
            rootView: ShareView(result: nil)
        )
        self.contentView = contentView
        self.addChild(contentView)
        self.view.addSubview(contentView.view)

        // set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor)
            .isActive = true
        contentView.view.bottomAnchor.constraint(
            equalTo: self.view.bottomAnchor
        ).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor)
            .isActive = true
        contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor)
            .isActive = true

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("close"),
            object: nil,
            queue: nil
        ) { _ in
            Task { @MainActor in
                self.close()
            }
        }

        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.first
                as? NSExtensionItem
        else {
            updateContentView(result: .failure("No items are shared."))
            return
        }

        Task {
            let result = await handleSharedItem(extensionItem)
            updateContentView(result: result)
        }
    }

    private func updateContentView(result: HandlingResult) {
        contentView!.rootView = ShareView(result: result)
    }

    func close() {
        // Close the share extension.
        self.extensionContext?.completeRequest(
            returningItems: [],
            completionHandler: nil
        )
    }
}

private let appGroup: String =
    "group.dev.norelease.musickit-tutorial.group"

private let listenLaterQueueKey: String = "listenLaterQueue"

enum HandlingResult {
    case failure(String)
    case success
}

private func handleSharedItem(_ sharedItem: NSExtensionItem) async
    -> HandlingResult
{
    // Ensure access to extensionItem and itemProvider
    guard
        let itemProvider = sharedItem.attachments?.first
    else {
        return .failure("No content are shared")
    }

    guard
        itemProvider.hasItemConformingToTypeIdentifier(
            UTType.url.identifier
        )
    else {
        return .failure("Item is not of type \(UTType.url.identifier)")
    }

    var loadedItem: NSSecureCoding
    do {
        loadedItem = try await itemProvider.loadItem(
            forTypeIdentifier: UTType.url.identifier,
            options: nil
        )
    } catch {
        return .failure("\(error)")
    }

    guard let url = loadedItem as? URL else {
        return .failure("Unexpected type: \(loadedItem)")
    }

    // Append the shapred url to the queue.
    // The containing app sees this queue and processes the urls in it.
    let userDefaults = UserDefaults(suiteName: appGroup)
    if var listenLaterQueue = userDefaults?.array(
        forKey: listenLaterQueueKey
    ) {
        listenLaterQueue.append(url.absoluteString)
        userDefaults?.set(
            listenLaterQueue,
            forKey: listenLaterQueueKey
        )
    } else {
        userDefaults?.set(
            [url.absoluteString],
            forKey: listenLaterQueueKey
        )
    }

    return .success

}
