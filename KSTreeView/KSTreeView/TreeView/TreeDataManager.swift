//
//  TreeDataManager.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 14/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import UIKit

protocol TreeCellDelegate {
    func renderTree()
}

class TreeDataManager<NodeCellType: TreeCell<NodeType>, NodeType: TreeNode> {
    typealias CellConfigurator = ((NodeCellType, NodeType)->(NodeCellType))
    
    private var tree: Tree<NodeType>?
    private var flattenedNodes = [NodeType]()
    private var dataSource: UITableViewDiffableDataSource<Section, NodeType>?
    private let cellConfigurator: ((NodeCellType, NodeType)->(NodeCellType))
    
    init(tableView: UITableView, depthPadding: CGFloat, cellConfigurator: @escaping CellConfigurator) {
        self.cellConfigurator = cellConfigurator
        self.dataSource = UITableViewDiffableDataSource(tableView: tableView) {
            tableView, indexPath, node in
            let treeCell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.ID,
                                                         for: indexPath) as! NodeCellType
            treeCell.configure(with: .init(node: node, depthPadding: depthPadding, delegate: self))
            
            return cellConfigurator(treeCell, node)
        }
        tableView.dataSource = self.dataSource
    }
    
    func updateData(shouldAnimate: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, NodeType>()
        snapshot.appendSections([Section.one])
        snapshot.appendItems(flattenedNodes, toSection: Section.one)
        dataSource?.apply(snapshot, animatingDifferences: shouldAnimate, completion: nil)
    }
    
    func flatten(_ treeNode: NodeType, flattenedNodes: [NodeType] = []) -> [NodeType] {
        var flattenedNodes = flattenedNodes
        flattenedNodes.append(treeNode)
        
        guard treeNode.areChildrenHidden == false else { return flattenedNodes }
        
        for childNode in treeNode.children {
            if childNode.children.isEmpty {
                flattenedNodes.append(childNode)
            } else {
                flattenedNodes = flatten(childNode, flattenedNodes: flattenedNodes)
            }
        }
        
        return flattenedNodes
    }
    
    func flatten(_ tree: Tree<NodeType>) -> [NodeType] {
        return tree.children.map { node in
            flatten(node)
        }.joined().map { $0 }
    }
}

extension TreeDataManager {
    
    func render(_ tree: Tree<NodeType>, shouldAnimate: Bool) {
        self.tree = tree
        self.flattenedNodes = flatten(tree)
        updateData(shouldAnimate: shouldAnimate)
    }
    
    func getNodeOrder(whenNode node: NodeType, movesTo indexPath: IndexPath) -> [BareNode] {
        var nodes = flattenedNodes.map{ $0.bareNode }
        nodes.removeAll{ $0.ID == node.ID }
        nodes.insert(node.bareNode, at: indexPath.row)
        return nodes
    }
    
    func node(withID ID: UUID) -> NodeType? {
        return flattenedNodes.first{ $0.ID == ID }
    }
    

    func reorderNode(using reorderDetails: TreeView<NodeCellType, NodeType>.NodeReorderDetails) {
        let indexOfDraggedBareNode = reorderDetails.tempNodeOrder.firstIndex{ $0.ID == reorderDetails.draggedBareNode.ID }
        
        var nodesBeforeTheDraggedBareNode = [BareNode]()
        
        // Here, we collect all the nodes before the dragged node and try to find who the parent is and also the
        // count of siblings between the dragged node and its parent
        // There are three cases to be handled when we try form a search space to find the parent node
        
        if let indexOfDraggedBareNode = indexOfDraggedBareNode {
            
            // CASE 1)
            // Forming a range requires the upper bound to be always greater than the lower bound
            // Here, the index needs to be atleast 2 to form a valid range after subtracting 1
            
            // CASE 2)
            // Here, we cannot form a range since there's only one node before the dragged node.
            // So we collect it direcly by its index
            
            // CASE 3)
            // The dragged node has no nodes before it
            // So, we assign it an empty array (I know its already empty :) Just trying to make the cases clear)
            
            if indexOfDraggedBareNode >= 2 {
                nodesBeforeTheDraggedBareNode = reorderDetails.tempNodeOrder[0...(indexOfDraggedBareNode - 1)].reversed()
            } else if indexOfDraggedBareNode == 1 {
                nodesBeforeTheDraggedBareNode = [reorderDetails.tempNodeOrder[0]]
            } else {
                nodesBeforeTheDraggedBareNode = []
            }
        }
        
        // CORE LOGIC
        // Finding Parent:-
        // Find the node above which has a lesser depth than the dragged node
        
        // Fidning the index of dragged node in its parent's children array
        // Count the number of nodes (Siblings) having the same depth as dragged node between the dragged node and its parent -> Child index of dragged node in
    
        var siblingsBetweenParentAndDestination = 0
        
        let newParentBareNode = nodesBeforeTheDraggedBareNode.first { node -> Bool in
            if node.depth == reorderDetails.proposedDepth {
                siblingsBetweenParentAndDestination += 1
            }
            return node.depth < reorderDetails.proposedDepth
        }
        
        let childIndex = siblingsBetweenParentAndDestination
        
        guard let draggedNode = node(withID: reorderDetails.draggedBareNode.ID), let tree = tree else {
            return
        }
        
        // Since reordering nodes can change parent-child relationships,
        // we reload the indexPaths associated with the following nodes using the renderNode method
        // 1) The new parent node
        // 2) The old parent node
        // 3) The dragged node
        
        let oldParentNode = draggedNode.parent
        
        // When the dragged node has no parent, it is a top level node and is a child of the tree
        // Here, we handle the cases when the dragged node is a child of a node and when it is a child
        // of a tree
        if let newParentBareNode = newParentBareNode, let newParentNode = node(withID: newParentBareNode.ID) {
            if childIndex <= (newParentNode.children.count - 1) {
                newParentNode.addChild(draggedNode, at: childIndex)
            } else {
                newParentNode.addChild(draggedNode)
            }
            renderNode(newParentNode)
        } else {
            if childIndex <= (tree.children.count - 1) {
                tree.addChild(draggedNode, at: childIndex)
            } else {
                tree.addChild(draggedNode)
            }
        }
        
        if let oldParentNode = oldParentNode {
            renderNode(oldParentNode)
        }
        
        renderNode(draggedNode)
        renderTree()
    }
}

extension TreeDataManager: TreeCellDelegate {
    func renderTree() {
        guard let tree = tree else { return }
        render(tree, shouldAnimate: true)
    }
    
    func renderNode(_ node: NodeType) {
        guard var snapshot = dataSource?.snapshot() else { return }
        snapshot.reloadItems([node])
        dataSource?.apply(snapshot)
    }
}

fileprivate extension TreeDataManager {
    enum Section {
        case one
    }
}

extension Collection {
    var validIndexRange: ClosedRange<Int> {
        return (0...(count - 1))
    }
}
