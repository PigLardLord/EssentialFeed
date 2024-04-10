//
// Created on 10/04/24 using Swift 5.0
//
        

import XCTest
import EssentialFeed

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}

protocol FeedImageView {
    associatedtype Image

    func display(_ model: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View
    private let imageTransformer: (Data) -> Image?
    
    init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    func didStartLoadingImageData(for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
    
    private struct InvalidImageDataError: Error {}
    
    func didFinishLoadingImageData(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishLoadingImageData(with: InvalidImageDataError(), for: model)
        }
        
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false))
    }
    
    func didFinishLoadingImageData(with error: Error, for model: FeedImage) {
        view.display(FeedImageViewModel(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true))
    }
}

final class FeedImagePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessageToView() {
        let (_, view) = makeSUT()
        
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages")
    }
    
    func test_didStartLoadingImageData_displayLoadingImage(){
        let (sut, view) = makeSUT()
        let image = uniqueImage()
        
        sut.didStartLoadingImageData(for: image)
        
        let model = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(model?.description, image.description)
        XCTAssertEqual(model?.location, image.location)
        XCTAssertNil(model?.image)
        XCTAssertEqual(model?.isLoading, true)
        XCTAssertEqual(model?.shouldRetry, false)
    }
    
    func test_didFinishLoadingImageDataWithError_stopLoadingAndEnablesRetry(){
        let (sut, view) = makeSUT()
        let image = uniqueImage()
        let error = anyNSError
        
        sut.didFinishLoadingImageData(with: error, for: image)
        
        let model = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(model?.description, image.description)
        XCTAssertEqual(model?.location, image.location)
        XCTAssertNil(model?.image)
        XCTAssertEqual(model?.isLoading, false)
        XCTAssertEqual(model?.shouldRetry, true)
    }
    
    func test_didFinishLoadingImageDataWithData_stopLoadinAndDisplaysImage(){
        let image = uniqueImage()
        let data = Data()
        let transformedData = AnyImage()
        let (sut, view) = makeSUT(trasformer: { _ in transformedData })
        
        sut.didFinishLoadingImageData(with: data, for: image)
        
        let model = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(model?.description, image.description)
        XCTAssertEqual(model?.location, image.location)
        XCTAssertEqual(model?.image, transformedData)
        XCTAssertEqual(model?.isLoading, false)
        XCTAssertEqual(model?.shouldRetry, false)
    }
    
    func test_didFinishLoadingImageDataWithData_stopLoadingAndEnablesRetryOnFailedTrasformation(){
        let image = uniqueImage()
        let data = Data()
        let failingTransformer: (Data) -> AnyImage? = { _ in nil }
        let (sut, view) = makeSUT(trasformer: failingTransformer)
        
        sut.didFinishLoadingImageData(with: data, for: image)
        
        let model = view.messages.first
        XCTAssertEqual(view.messages.count, 1)
        XCTAssertEqual(model?.description, image.description)
        XCTAssertEqual(model?.location, image.location)
        XCTAssertEqual(model?.image, nil)
        XCTAssertEqual(model?.isLoading, false)
        XCTAssertEqual(model?.shouldRetry, true)
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
    
    private struct AnyImage: Equatable {}
    
    private class ViewSpy: FeedImageView {
        private(set) var messages = [FeedImageViewModel<AnyImage>]()
        
        func display(_ model: FeedImageViewModel<AnyImage>) {
            messages.append(model)
        }
    }
}

