//
//  JSONDecodingTests.swift
//  ResticGUITests
//

import XCTest
@testable import ResticGUI

class JSONDecodingTests: XCTestCase {
	let jsonDecoder = JSONDecoder()
	
	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testSnapshots() {
		let testData = """
[{"time":"2024-11-11T14:43:15.284926-07:00","tree":"0afb87d4eaa75a68c74004f2345a65b273b158adcc977eeb580322b9c3b585c9","paths":["/backupPath"],"hostname":"host.local","username":"User","uid":501,"gid":20,"tags":["tag1","tag2","tag3"],"program_version":"restic 0.17.1","summary":{"backup_start":"2024-11-11T14:43:15.284926-07:00","backup_end":"2024-11-11T14:43:16.214376-07:00","files_new":33,"files_changed":0,"files_unmodified":0,"dirs_new":22,"dirs_changed":0,"dirs_unmodified":0,"data_blobs":32,"tree_blobs":22,"data_added":553551,"data_added_packed":160018,"total_files_processed":33,"total_bytes_processed":526564},"id":"fba3e4b067810902bdc82467327d4bd517b564775fec2f4c3814fd2cc7def929","short_id":"fba3e4b0"},{"time":"2024-11-13T12:10:46.292296-07:00","tree":"6ab31f82899aa7b753adcb9c9169496d8e308e1f15710d6dbbb8447c780bbbf8","paths":["/path1","/path2","/path3"],"hostname":"host.local","username":"User","uid":501,"gid":20,"tags":["tag1","tag2","tag3"],"program_version":"restic 0.17.1","summary":{"backup_start":"2024-11-13T12:10:46.292296-07:00","backup_end":"2024-11-13T12:10:47.192445-07:00","files_new":34,"files_changed":0,"files_unmodified":0,"dirs_new":22,"dirs_changed":0,"dirs_unmodified":0,"data_blobs":7,"tree_blobs":12,"data_added":480575,"data_added_packed":126119,"total_files_processed":34,"total_bytes_processed":556506},"id":"52e6b866259f07cf752c9d989a76c6d9bdae568733ab9d871210063c43aadf84","short_id":"52e6b866"}]
""".data(using: .utf8)!
		
		do {
			let obj = try jsonDecoder.decode([Snapshot].self, from: testData)
			print(obj)
			XCTAssertNotEqual(obj.first!.getDate(), Date.init(timeIntervalSince1970: 0))
			
		} catch {
			XCTFail("\(error)")
		}
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}
	
}
