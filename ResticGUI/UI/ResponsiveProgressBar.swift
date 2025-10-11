//
//  ResponsiveProgressBar.swift
//  ResticGUI
//
//

import AppKit

class ResponsiveProgressBar: NSProgressIndicator {
	@IBOutlet var viewCon: ViewController!
	override func mouseUp(with event: NSEvent) {
		if let popover = viewCon.completedBackupPopover {
			popover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
		}
	}
}
