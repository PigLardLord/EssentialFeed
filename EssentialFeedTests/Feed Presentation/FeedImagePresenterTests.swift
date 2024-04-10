//
// Created on 10/04/24 using Swift 5.0
//
        

import XCTest
import EssentialFeed

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessageToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages")
    }
    
    func test_didStartLoadingImageData_displayLoadingImage(){
        let (sut, view) = makeSUT()
        let image = uniqueImage()
        
        sut.didStartLoadingImageData(for: image)
        
        expect(view, with: image, toPresent: nil, isLoading: true, showRetry: false)
    }
    
    func test_didFinishLoadingImageDataWithError_stopLoadingAndEnablesRetry(){
        let (sut, view) = makeSUT()
        let image = uniqueImage()
        let error = anyNSError
        
        sut.didFinishLoadingImageData(with: error, for: image)
        
        expect(view, with: image, toPresent: nil, isLoading: false, showRetry: true)
    }
    
    func test_didFinishLoadingImageDataWithData_stopLoadinAndDisplaysImage(){
        let image = uniqueImage()
        let data = Data()
        let transformedData = AnyImage()
        let (sut, view) = makeSUT(trasformer: { _ in transformedData })
        
        sut.didFinishLoadingImageData(with: data, for: image)
        
        expect(view, with: image, toPresent: transformedData, isLoading: false, showRetry: false)
    }
    
    func test_didFinishLoadingImageDataWithData_stopLoadingAndEnablesRetryOnFailedTrasformation(){
        let image = uniqueImage()
        let data = Data()
        let (sut, view) = makeSUT(trasformer: fail)
        
        sut.didFinishLoadingImageData(with: data, for: image)
        
        expect(view, with: image, toPresent: nil, isLoading: false, showRetry: true)
    }
    
    
    // Helpers
    
    private func makeSUT(
        trasformer: @escaping (Data) -> AnyImage? = { _ in nil },
        file: StaticString = #filePath,
        line: UInt = #line) -> (sut: FeedImagePresenter<ViewSpy, AnyImage>, view: ViewSpy) {
        let view = ViewSpy()
        let sut = FeedImagePresenter(view: view, imageTransformer: trasformer)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private func expect(
        _ view:ViewSpy,
        with feedImage: FeedImage,
        toPresent imageData: AnyImage?,
        isLoading: Bool,
        showRetry: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let model = view.messages.first
        XCTAssertEqual(view.messages.count, 1, file: file, line: line)
        XCTAssertEqual(model?.description, feedImage.description, file: file, line: line)
        XCTAssertEqual(model?.location, feedImage.location, file: file, line: line)
        XCTAssertEqual(model?.image, imageData, file: file, line: line)
        XCTAssertEqual(model?.isLoading, isLoading, file: file, line: line)
        XCTAssertEqual(model?.shouldRetry, showRetry, file: file, line: line)
    }

    private var fail: (Data) -> AnyImage? {
        return { _ in nil }
    }
    
    private struct AnyImage: Equatable {}
    
    private class ViewSpy: FeedImageView {
        private(set) var messages = [FeedImageViewModel<AnyImage>]()
        
        func display(_ model: FeedImageViewModel<AnyImage>) {
            messages.append(model)
        }
    }
}

