//
//  DefaultsKeys.swift
//  ResticGUI
//


struct DefaultsKeys {
	// User Configuration
	public static let scanAhead = "Scan Ahead"
	public static let globalRepoSelection = "Global Repo Selection"
	public static let backupQoS = "Backup QoS"
	public static let limitBackgroundCoreCount = "Limit Background Core Count"
	public static let batteryQoS = "QoS Background on Battery"
	public static let lowPowerQoS = "QoS Background on Low Power"
	public static let storageQoS = "Storage QoS"
	
	public static let snapshotDateFormat = "Snapshot Date Format"
	
	public static let resticLocation = "Restic Location"
	public static let cacheDirectory = "Cache Directory"
	public static let globalExclusions = "Global Exclusions"
	public static let isGlobalExclusionsCaseSensitive = "Global Exclusions Case Sensitive"
	public static let globalExcludePatternFile = "Global Exclude Pattern File"
	public static let globalEnvTable = "Global Enviorment Table"
	

	// State-Saving
	public static let lastSelectedProfile = "LastSelectedProfile"
	public static let profileEditorTab = "ProfileEditorTabIndex"
	public static let selectedRepo = "Selected Repo"
	public static let viewSizeRestoreView = "RestoreViewSheet View Size"
	public static let prefWindowLastTab = "PrefWindowLastSelectedTab"
}
