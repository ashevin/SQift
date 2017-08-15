//
//  CheckpointTests.swift
//  SQift
//
//  Created by Christian Noon on 8/13/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation
import SQift
import SQLite3
import XCTest

class CheckpointTestCase: BaseConnectionTestCase {

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        do {
            try connection.execute("PRAGMA journal_mode = WAL")
        } catch {
            // No-op
        }
    }

    // MARK: - Tests

    func testThatConnectionCanCheckpointDatabaseUsingPassiveCheckpointMode() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            // When
            let result = try connection.checkpoint(mode: .passive)

            // Then
            XCTAssertEqual(result.logFrames, 15)
            XCTAssertEqual(result.checkpointedFrames, 15)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingFullCheckpointMode() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            // When
            let result = try connection.checkpoint(mode: .full)

            // Then
            XCTAssertEqual(result.logFrames, 15)
            XCTAssertEqual(result.checkpointedFrames, 15)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingRestartCheckpointMode() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            // When
            let result = try connection.checkpoint(mode: .restart)

            // Then
            XCTAssertEqual(result.logFrames, 15)
            XCTAssertEqual(result.checkpointedFrames, 15)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionCanCheckpointDatabaseUsingTruncateCheckpointMode() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            // When
            let result = try connection.checkpoint(mode: .truncate)

            // Then
            XCTAssertEqual(result.logFrames, 0) // CN (8/14/17) - DB is being truncated but results are always 0?
            XCTAssertEqual(result.checkpointedFrames, 0)
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }

    func testThatConnectionThrowsBusyErrorWhenCheckpointingBusyDatabase() {
        do {
            // Given
            try TestTables.insertDummyAgents(count: 1_000, connection: connection)

            let readConnection = try Connection(storageLocation: storageLocation, readOnly: true)

            let expectation = self.expectation(description: "agents should be retrieved from database")
            var agents: [Agent]?
            var checkpointError: Error?

            // When
            DispatchQueue.utility.async {
                do {
                    agents = try readConnection.query("SELECT * FROM agents")
                    expectation.fulfill()
                } catch {
                    // No-op
                }
            }

            DispatchQueue.utility.asyncAfter(seconds: 0.001) {
                do {
                    _ = try self.connection.checkpoint(mode: .truncate)
                } catch {
                    checkpointError = error
                }
            }

            waitForExpectations(timeout: timeout, handler: nil)

            // Then
            XCTAssertEqual(agents?.count, 1_002)
            XCTAssertNotNil(checkpointError)

            if let error = checkpointError as? SQLiteError {
                XCTAssertEqual(error.code, SQLITE_BUSY)
                XCTAssertEqual(error.message, "database is locked")
            }
        } catch {
            XCTFail("Test encountered unexpected error: \(error)")
        }
    }
}
