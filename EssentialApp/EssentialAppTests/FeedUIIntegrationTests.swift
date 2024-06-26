//
// Created on 27/02/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//
        

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS
import EssentialApp

final class FeedUIIntegrationTests: XCTestCase {
    
    func test_feedView_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppereance()
        
        XCTAssertEqual(sut.title, localized("FEED_VIEW_TITLE"))
    }
    
    func test_loadFeedActions_requestsFeedFromLoader() {
        let (sut, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")
    
        sut.simulateAppereance()
        XCTAssertEqual(loader.loadFeedCallCount, 1, "Expected no loading requests before view is loaded")
    
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2, "Expected another loading request once user initiates a reload")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3, "Expected yet another loading request once user initiates another reload")
    }
    
    func test_viewIsAppearing_showsLoadingIndicator() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed succesfully")
    
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")
    
        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading is completed with an error")
    }
    
    func test_loadFeedCompletion_rendersSuccesfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    func test_loadFeedCompletion_shouldNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0])
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, localized("FEED_VIEW_CONNECTION_ERROR"))
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first view becomes visible")
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected first image URL request once first view becomes visible")
    }
    
    func test_feedImageView_cancelImageURLLoadingWhenNotVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.canceledImageUrls, [], "Expected no canceled image URL until image is not visible")
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.canceledImageUrls, [image0.url], "Expected first image URL canceled once first image is no longer visible")
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.canceledImageUrls, [image0.url, image1.url], "Expected two image URLs canceled once second image is no longer visible")
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected loading indicator for second view while loading second image")

        loader.completeImageLoading(at: 0)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected no loading indicator state change for second view once first image loading completes successfully")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator state change for first view once second image loading completes with error")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for second view once second image loading completes with error")
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
            let (sut, loader) = makeSUT()

            sut.simulateAppereance()
            loader.completeFeedLoading(with: [makeImage(), makeImage()])

            let view0 = sut.simulateFeedImageViewVisible(at: 0)
            let view1 = sut.simulateFeedImageViewVisible(at: 1)
            XCTAssertEqual(view0?.renderedImage, .none, "Expected no image for first view while loading first image")
            XCTAssertEqual(view1?.renderedImage, .none, "Expected no image for second view while loading second image")

            let imageData0 = UIImage.make(withColor: .red).pngData()!
            loader.completeImageLoading(with: imageData0, at: 0)
            XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view once first image loading completes successfully")
            XCTAssertEqual(view1?.renderedImage, .none, "Expected no image state change for second view once first image loading completes successfully")

            let imageData1 = UIImage.make(withColor: .blue).pngData()!
            loader.completeImageLoading(with: imageData1, at: 1)
            XCTAssertEqual(view0?.renderedImage, imageData0, "Expected no image state change for first view once second image loading completes successfully")
            XCTAssertEqual(view1?.renderedImage, imageData1, "Expected image for second view once second image loading completes successfully")
        }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action for first view while loading first image")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry action for second view while loading second image")
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData, at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry action state change for second view once first image loading completes successfully")
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action state change for first view once second image loading completes with error")
        XCTAssertEqual(view1?.isShowingRetryAction, true, "Expected retry action for second view once second image loading completes with error")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(view?.isShowingRetryAction, false, "Expected no retry action while loading image")
        
        let invalidImageData = Data("invalid image data".utf8)
        loader.completeImageLoading(with: invalidImageData, at: 0)
        XCTAssertEqual(view?.isShowingRetryAction, true, "Expected retry action once image loading completes with invalid image data")
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected two image URL request for the two visible views")
        
        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected only two image URL requests before retry action")
        
        view0?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url], "Expected third imageURL request after first view retry action")
        
        view1?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url, image1.url], "Expected fourth imageURL request after second view retry action")
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until image is near visible")
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first image is near visible")
        
        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image is near visible")
    }
    
    func test_feedImageView_loadImageURLWhenWillDisplay() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until willDisplay is called")
        
        sut.simulateFeedImageViewWillDisplay(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image URL request once first image will display")
        
        sut.simulateFeedImageViewWillDisplay(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expected second image URL request once second image will display")
    }
    
    func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.canceledImageUrls, [], "Expected no cancelled image URL requests until image is not near visible")
        
        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.canceledImageUrls, [image0.url], "Expected first cancelled image URL request once first image is not near visible anymore")
        
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.canceledImageUrls, [image0.url, image1.url], "Expected second cancelled image URL request once second image is not near visible anymore")
    }
    
    func test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewNotVisible(at: 0)
        loader.completeImageLoading(with: anyImageData, at: 0)

        XCTAssertNil(view?.renderedImage, "Expected no image rendered once it is not visible anymore")
    }
    
    func test_loadFeedCompletion_dispatchedFromBackgroundToMainTherad() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        
        let exp = expectation(description: "wait for background queue")
        DispatchQueue.global(qos: .background).async {
            loader.completeFeedLoading(at: 0)
            exp.fulfill()
        }
        wait(for: [exp])
    }
    
    func test_loadImageDauaCompletion_dispatchedFromBackgroundToMainTherad() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppereance()
        loader.completeFeedLoading(with: [makeImage()])
        sut.simulateFeedImageViewVisible(at: 0)
        
        let exp = expectation(description: "wait for background queue")
        DispatchQueue.global(qos: .background).async {
            loader.completeImageLoading(with: self.anyImageData, at: 0)
            exp.fulfill()
        }
        wait(for: [exp])
    }
    
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, store: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(loader: loader, imageLoader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "http://a-url.com")!) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line){
        guard sut.numberOfRenderedFeedImageViews() == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews()) instead", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedImageView(at: index)
        
        guard let cell = view as? FeedImageCell else {
            return XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        let shouldLocationBeVisible = (image.location != nil)
        XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible, "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.locationText, image.location, "Expected location text to be \(String(describing: image.location)) for image  view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.descriptionText, image.description, "Expected description text to be \(String(describing: image.description)) for image view at index (\(index)", file: file, line: line)
    }
    
    private var anyImageData : Data {
        UIImage.make(withColor: .red).pngData()!
    }
}

extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var isShowingImageLoadingIndicator: Bool {
        return feedImageContainer.isShimmering
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}
