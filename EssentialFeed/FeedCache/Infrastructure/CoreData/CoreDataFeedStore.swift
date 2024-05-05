//
// Created on 04/02/24 using Swift 5.0
// Copyright © 2024 Cortado AG. All rights reserved.
//


import Foundation
import CoreData

public final class CoreDataFeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeUrl: URL) throws {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        container = try NSPersistentContainer.load(modelName: "FeedStore", from: storeUrl, in: bundle)
        context = container.newBackgroundContext()
    }
    
    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
    
    deinit {
        cleanUpReferencesToPersistentStores()
    }
}
