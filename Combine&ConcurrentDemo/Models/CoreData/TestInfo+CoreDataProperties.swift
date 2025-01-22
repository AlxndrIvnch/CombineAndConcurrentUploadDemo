//
//  TestInfo+CoreDataProperties.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//
//

import Foundation
import CoreData

extension TestInfo : Identifiable {
    @NSManaged public var id: UUID
}

extension TestInfo {
    @NSManaged public var foulderName: String
    @NSManaged public var threadsCount: Int16
    @NSManaged public var time: Double
    @NSManaged public var images: [URL]

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestInfo> {
        return NSFetchRequest<TestInfo>(entityName: "TestInfo")
    }
}

extension TestInfo {
    var imagesCount: Int { images.count }
}
