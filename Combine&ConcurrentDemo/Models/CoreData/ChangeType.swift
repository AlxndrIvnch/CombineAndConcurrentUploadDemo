//
//  ChangeType.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 29.03.2023.
//

import CoreData.NSManagedObjectContext

enum ChangeType: Hashable {
    case inserted, deleted, updated
    
    var userInfoKey: String {
        switch self {
        case .inserted: return NSInsertedObjectsKey
        case .deleted: return NSDeletedObjectsKey
        case .updated: return NSUpdatedObjectsKey
        }
    }
}
