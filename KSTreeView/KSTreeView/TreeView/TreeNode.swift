//
//  Item.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 14/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import Foundation

/// Make sure you declare parent as weak as it can cause a memory leak
protocol TreeNode: class, Hashable {
    var ID: UUID { get }
    var tree: Tree<Self>? { get set }
    var parent: Self? { get set}
    var children: [Self] { get set}
    /// This property dictates whether the child nodes are shown or hidden
    var areChildrenHidden: Bool { get set }
}

extension TreeNode {
    
    var depth: Int {
        var count = 0
        var currentParent = self.parent
        while currentParent != nil {
            count += 1
            currentParent = currentParent?.parent
        }
        return count
    }
    
    /// Returns the max depth in its hierarchy
    var maxDepth: Int {
        return getMaxDepth(node: self)
    }
    
    var hasChildren: Bool {
        return !children.isEmpty
    }
    
    /// Returns the count of all the nodes under it
    var count: Int {
        return getCount(for: self)
    }
    
    var isTopLevelNode: Bool {
        return tree != nil && parent == nil
    }
    
    var hasParent: Bool {
        return parent == nil
    }
    
    var bareNode: BareNode {
        return BareNode(ID: ID, depth: depth, children: children.map{ $0.bareNode })
    }
    
    func setParent(_ parent: Self) {
        self.parent = parent
    }
    
    func addChild(_ child: Self, at index: Int? = nil) {
        removeParentRelationship(for: child)
        child.setParent(self)
        if let index = index {
            self.children.insert(child, at: index)
        } else {
            self.children.append(child)
        }
    }
    
    func addChildren(_ children: [Self]) {
        children.forEach { child in
            addChild(child)
        }
    }
    
    func removeParentRelationship() {
        guard let parent = self.parent else { return }
        parent.children.removeAll{ $0 == self }
        self.parent = nil
    }
    
}

extension TreeNode {
    
    private func getMaxDepth(node: Self) -> Int {
        if node.children.isEmpty {
            return node.depth
        }
        return node.children.map { child in
            getMaxDepth(node: child)
        }.max() ?? 0
    }
    
    private func getCount(for node: Self) -> Int {
        if node.children.isEmpty {
            return 0
        }
        return node.children.count + node.children.map {
            getCount(for: $0)
        }.reduce(0, +)
    }
    
    private func removeParentRelationship(for child: Self) {
        if let parent = child.parent {
            parent.children.removeAll{ $0 == child }
            child.parent = nil
        } else if let tree = child.tree, child.isTopLevelNode {
            tree.children.removeAll{ $0 == child }
            child.tree = nil
        }
    }
}

extension TreeNode {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
        hasher.combine(areChildrenHidden)
        hasher.combine(depth)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ID == rhs.ID
    }
}


class BareNode: Hashable {
    let ID: UUID
    let depth: Int
    var children: [BareNode]
    var hasChildren: Bool {
        return !children.isEmpty
    }
    
    init(ID: UUID, depth: Int, children: [BareNode]) {
        self.ID = ID
        self.depth = depth
        self.children = children
    }
    
    static func == (lhs: BareNode, rhs: BareNode) -> Bool {
        return lhs.ID == rhs.ID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }
}
