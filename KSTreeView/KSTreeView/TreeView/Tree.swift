//
//  Tree.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 25/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import Foundation

class Tree<NodeType: TreeNode> {
    var children: [NodeType] = []
    init?(children: [NodeType]) {
        guard areTopLevelItems(children) else { return nil }
        self.children = children.map{ child in
            child.tree = self
            return child
        }
    }
}

extension Tree {
    func addChild(_ child: NodeType, at index: Int? = nil) {
        removeParentRelationship(for: child)
        child.tree = self
        if let index = index {
            self.children.insert(child, at: index)
        } else {
            self.children.append(child)
        }
    }
    
    private func removeParentRelationship(for child: NodeType) {
        if let parent = child.parent {
            parent.children.removeAll{ $0 == child }
            child.parent = nil
        } else if let tree = child.tree {
            tree.children.removeAll{ $0 == child }
            child.tree = nil
        }
    }
    
    private func areTopLevelItems(_ children: [NodeType]) -> Bool {
        for child in children {
            guard child.hasParent else { return false }
        }
        return true
    }
}

