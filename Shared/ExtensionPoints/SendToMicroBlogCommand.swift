//
//  SendToMicroBlogCommand.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 1/8/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import AppKit
import Articles
import RSCore

// Not undoable.

final class SendToMicroBlogCommand: SendToCommand {

	let title = "Micro.blog"
	let image: RSImage? = AppAssets.microblogIcon

	private let microBlogApp = UserApp(bundleID: "blog.micro.mac")

	func canSendObject(_ object: Any?, selectedText: String?) -> Bool {

		microBlogApp.updateStatus()
		guard microBlogApp.existsOnDisk, let article = (object as? ArticlePasteboardWriter)?.article, let _ = article.preferredLink else {
			return false
		}

		return true
	}
	
	func sendObject(_ object: Any?, selectedText: String?) {

		guard canSendObject(object, selectedText: selectedText) else {
			return
		}
		guard let article = (object as? ArticlePasteboardWriter)?.article else {
			return
		}

		Task {
			guard await microBlogApp.launchIfNeeded(), microBlogApp.bringToFront() else {
				return
			}

			// TODO: get text from contentHTML or contentText if no title and no selectedText.
			// TODO: consider selectedText.

			let s = article.attributionString + article.linkString

			let urlQueryDictionary = ["text": s]
			guard let urlQueryString = urlQueryDictionary.urlQueryString else {
				return
			}
			guard let url = URL(string: "microblog://post?" + urlQueryString) else {
				return
			}

			NSWorkspace.shared.open(url)
		}
	}
}

private extension Article {

	var attributionString: String {

		// Feed name, or feed name + author name (if author is specified per-article).
		// Includes trailing space.

		if let feedName = webFeed?.nameForDisplay, let authorName = authors?.first?.name {
			return feedName + ", " + authorName + ": "
		}
		if let feedName = webFeed?.nameForDisplay {
			return feedName + ": "
		}
		return ""
	}

	var linkString: String {

		// Title + link or just title (if no link) or just link if no title

		if let title = title, let link = preferredLink {
			return "[" + title + "](" + link + ")"
		}
		if let preferredLink = preferredLink {
			return preferredLink
		}
		if let title = title {
			return title
		}
		return ""
	}

}
