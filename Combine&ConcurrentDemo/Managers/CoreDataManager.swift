//
//  CoreDataManager.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation
import CoreData
import Combine

final class CoreDataManager {

    // MARK: - Core Data Stack
    
    static private var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataDB")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    static var context: NSManagedObjectContext {
        return CoreDataManager.persistentContainer.viewContext
    }

    static func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - Publishers

extension CoreDataManager {
    static func saveObjectsPublisher<T: NSManagedObject>(for type: T.Type,
                                                  changeTypes: [ChangeType] = [.updated, .inserted, .deleted]) -> AnyPublisher<[ChangeType: [T]], Never> {
        let notification = NSManagedObjectContext.didSaveObjectsNotification
        return NotificationCenter.default.publisher(for: notification, object: context)
            .compactMap({ notification in
               return changeTypes.reduce(into: [:]) { dictionary, type in
                    guard let objects = notification.userInfo?[type.userInfoKey] as? Set<NSManagedObject> else { return }
                    dictionary[type] = objects.compactMap({ $0 as? T })
                }
            })
            .share()
            .eraseToAnyPublisher()
    }
}

// MARK: - CRUD

extension CoreDataManager {
    static func saveTestInfo(_ validTestInfo: ValidTestInfo) throws {
        let testInfo = TestInfo(context: context)
        testInfo.id = UUID()
        testInfo.foulderName = validTestInfo.foulderName
        testInfo.threadsCount = validTestInfo.threadsCount
        testInfo.time = validTestInfo.time
        testInfo.images = validTestInfo.images
        try context.save()
    }
    
    static func getTestsInfo() throws -> [TestInfo] {
        return try context.fetch(TestInfo.fetchRequest()).reversed()
    }
    
    static func deleteAll() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TestInfo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
    }
}
