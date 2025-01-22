//
//  Changes.swift
//  Combine&ConcurrentDemo
//
//  Created by alexander.ivanchenko on 28.03.2023.
//

import Foundation

// MARK: - Static Instances

extension Changes {
    static let none = Changes(inserted: nil, removed: nil, updated: nil, insertedSection: [], removedSection: [], scrollTo: nil)
}

struct Changes: Equatable {
    
    // MARK: - Properties
    
    private(set) var inserted: [IndexPath]
    private(set) var removed: [IndexPath]
    private(set) var updated: [IndexPath]
    
    private(set) var insertedSection: [Int] = []
    private(set) var removedSection: [Int] = []

    let scrollTo: IndexPath?
    
    var isEmpty: Bool { inserted.isEmpty && removed.isEmpty && updated.isEmpty }
    
    // MARK: - SectionAction
    
    enum SectionAction {
        case insert
        case remove
    }
    
    // MARK: - Initializers
    
    init(inserted: [Int] = [], removed: [Int] = [], updated: [Int] = [],
         section: Int = 0, sectionAction: SectionAction? = nil, scrollTo: IndexPath? = nil) {
        self.inserted = inserted.createIndexPaths(for: section)
        self.removed = removed.createIndexPaths(for: section)
        self.updated = updated.createIndexPaths(for: section)
        self.scrollTo = scrollTo
        switch sectionAction {
        case .insert: self.insertedSection = [section]
        case .remove: self.removedSection = [section]
        case .none: break
        }
    }
    
    init(inserted: [IndexPath] = [], removed: [IndexPath] = [], updated: [IndexPath] = [],
         insertedSection: [Int] = [], removedSection: [Int] = [], scrollTo: IndexPath? = nil) {
        self.inserted = inserted
        self.removed = removed
        self.updated = updated
        self.scrollTo = scrollTo
        self.insertedSection = insertedSection
        self.removedSection = removedSection
    }
    
    init(inserted: Range<Int>? = nil, removed: Range<Int>? = nil, updated: Range<Int>? = nil,
         section: Int = 0, sectionAction: SectionAction? = nil, scrollTo: IndexPath? = nil) {
        if let inserted = inserted {
            self.inserted = inserted.createIndexPaths(for: section)
        } else {
            self.inserted = []
        }
        
        if let removed = removed {
            self.removed = removed.createIndexPaths(for: section)
        } else {
            self.removed = []
        }
        
        if let updated = updated {
            self.updated = updated.createIndexPaths(for: section)
        } else {
            self.updated = []
        }
        self.scrollTo = scrollTo
        switch sectionAction {
        case .insert: self.insertedSection = [section]
        case .remove: self.removedSection = [section]
        case .none: break
        }
    }
    
    init(inserted: Int? = nil, removed: Int? = nil, updated: Int? = nil,
         section: Int = 0, sectionAction: SectionAction? = nil, scrollTo: IndexPath? = nil) {
        if let inserted = inserted {
            self.inserted = [IndexPath(item: inserted, section: section)]
        } else {
            self.inserted = []
        }
        
        if let removed = removed {
            self.removed = [IndexPath(item: removed, section: section)]
        } else {
            self.removed = []
        }
        
        if let updated = updated {
            self.updated = [IndexPath(item: updated, section: section)]
        } else {
            self.updated = []
        }
        self.scrollTo = scrollTo
        switch sectionAction {
        case .insert: self.insertedSection = [section]
        case .remove: self.removedSection = [section]
        case .none: break
        }
    }
    
    init(inserted: IndexPath? = nil, removed: IndexPath? = nil, updated: IndexPath? = nil,
         insertedSection: [Int] = [], removedSection: [Int] = [], scrollTo: IndexPath? = nil) {
        if let inserted = inserted {
            self.inserted = [inserted]
        } else {
            self.inserted = []
        }
        
        if let removed = removed {
            self.removed = [removed]
        } else {
            self.removed = []
        }
        
        if let updated = updated {
            self.updated = [updated]
        } else {
            self.updated = []
        }
        self.scrollTo = scrollTo
        self.insertedSection = insertedSection
        self.removedSection = removedSection
    }
    
    init<T: Hashable>(new: [T], old: [T], section: Int = 0, sectionAction: SectionAction? = nil, scrollTo: IndexPath? = nil) {
        var removed = Set<Int>()
        var inserted = Set<Int>()
        let difference = new.difference(from: old).inferringMoves()
        difference.forEach {
            switch $0 {
            case .remove(offset: let index, element: _, associatedWith: _):
                removed.insert(index)
            case .insert(offset: let index, element: _, associatedWith: _):
                inserted.insert(index)
            }
        }
        self.inserted = inserted.subtracting(removed).createIndexPaths(for: section)
        self.removed = removed.subtracting(inserted).createIndexPaths(for: section)
        self.updated = inserted.intersection(removed).createIndexPaths(for: section)
        
        self.scrollTo = scrollTo
        
        switch sectionAction {
        case .insert: self.insertedSection = [section]
        case .remove: self.removedSection = [section]
        case .none: break
        }
    }
    
    init<T: Hashable>(new: [[T]], old: [[T]], scrollTo: IndexPath? = nil) {
        var removed = Set<Int>()
        var inserted = Set<Int>()
        let difference = new.difference(from: old).inferringMoves()
        difference.forEach {
            switch $0 {
            case .remove(offset: let index, element: _, associatedWith:_):
                removed.insert(index)
            case .insert(offset: let index, element: _, associatedWith: _):
                inserted.insert(index)
            }
        }
        let insertedSections = inserted.subtracting(removed)
        self.insertedSection = Array(insertedSections)
        self.inserted = insertedSections.flatMap { new[$0].indices.createIndexPaths(for: $0) }
        
        let removedSections = removed.subtracting(inserted)
        self.removedSection = Array(removedSections)
        self.removed = removedSections.flatMap { old[$0].indices.createIndexPaths(for: $0) }
        
        self.updated = []
        self.scrollTo = scrollTo
     
        let updatedSections = removed.intersection(inserted)
        updatedSections.forEach { section in
            let newItems = new[section]
            let oldItems = old[section]
            let difference = newItems.difference(from: oldItems).inferringMoves()
            difference.forEach {
                switch $0 {
                case .remove(offset: let index, element: _, associatedWith:_):
                    self.removed.append(IndexPath(item: index, section: section))
                case .insert(offset: let index, element: _, associatedWith: _):
                    self.inserted.append(IndexPath(item: index, section: section))
                }
            }
        }
    }
}

