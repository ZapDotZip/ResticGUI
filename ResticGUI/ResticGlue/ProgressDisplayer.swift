//
//  ProgressDisplayer.swift
//  ResticGUI
//

/// Protocol for communicating between an async progress task and a user interface to display determinate progress from a running task.
/// > Important: The implementing class is responsible for ensuring UI updates happen on the main thread.
protocol ProgressDisplayer<S> {
	associatedtype S
	
	/// Called when the task first starts or when the max progress value changes.
	/// - Parameters:
	///   - value: The current progress value.
	///   - max: The maximum value for the progress.
	func setProgressBar(to value: Double, max: Double)
	
	/// Indicates that the task is currently running with indeterminate progress.
	/// - Parameter isIndeterminate: Whether or not the task's progress is indeterminate.
	func setIndeterminate(_ isIndeterminate: Bool)
	
	/// Called when the progress changes.
	/// - Parameters:
	///   - value: The updated progress value.
	///   - label: Progress text to display.
	func updateProgress(to value: Double, infoText: String?)
	
	/// Called when an error occurs during the task.
	/// - Parameter error: The error to display to the user.
	/// - Parameter isFatal: Whether or not the error was fatal.
	func displayError(_ error: Error, isFatal: Bool)
	
	/// Called when the task ends. If the task returns an error
	/// - Parameter summary: A summary of the task.
	/// - Parameter error: The error the task finished with, if any.
	func finish(summary: S?, with error: Error?)
	
}
