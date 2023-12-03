//
//  CodableEssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Giovanni Trovato on 26/11/23.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(
                id: self.id,
                description: self.description,
                location: self.location,
                url: self.url)
        }
    }
    
    private let storeUrl: URL
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeUrl) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let decodedCache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: decodedCache.localFeed, timestamp: decodedCache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion){
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map {CodableFeedImage($0)} , timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeUrl)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_retireve_DeliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retireve_HasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "wait retrieve")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                    case (.empty, .empty):
                        break
                    default:
                        XCTFail("Expected retrieving twice delivers same empty result, got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retireve_AfterInsertinonEmptyCacheDeliversInsertedData() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let exp = expectation(description: "wait retrieve")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected no insertion error got \(insertionError!) instead")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retireve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "wait retrieve")
        
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected no insertion error got \(insertionError!) instead")
            
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                        case let (.found(firstFeed, firstTimestamp), .found(secondFeed, secondTimestamp)):
                            XCTAssertEqual(firstFeed, feed)
                            XCTAssertEqual(firstTimestamp, timestamp)
                            
                            XCTAssertEqual(secondFeed, feed)
                            XCTAssertEqual(secondTimestamp, timestamp)
                            
                        default:
                            XCTFail("Expected retrieving twice from the cache felivers same feed: \(feed) and  \(timestamp), got \(firstResult) and \(secondResult) instead")
                    }
                    exp.fulfill()
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }

    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let url = testSpecificimageFeedUrl
        let sut = CodableFeedStore(storeUrl: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for retrieval")
        
        sut.retrieve { retrieveResult in
            switch (expectedResult, retrieveResult) {
                case (.empty, .empty):
                    break
                case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                    XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                    XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
                default:
                    XCTFail("Expected retrieval with \(expectedResult), got \(retrieveResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private var testSpecificimageFeedUrl: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificimageFeedUrl)
    }

}

