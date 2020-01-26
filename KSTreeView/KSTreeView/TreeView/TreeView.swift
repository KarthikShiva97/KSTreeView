//
//  Tree.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 14/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import UIKit

class TreeView<CellType: TreeCell<NodeType>, NodeType: TreeNode>: UIViewController,
UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate  {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let hintView = HintView()
    private var lastInteractedCell: CellType?
    private var lastDroppedIndexPath: IndexPath?
    
    private var lastAreChildrenHiddenState: Bool?
    private var xValueRangesVsDepthMap = [ClosedRange<CGFloat>: Int]()
    private let distanceBetweenHintViewDepthsInXaxis: CGFloat = 15
    
    private let maxAllowedDepth = 3
    private let depthPadding: CGFloat
    private let dataManager: TreeDataManager<CellType, NodeType>
    
    init(depthPadding: CGFloat = 45, cellConfigurator: @escaping TreeDataManager<CellType, NodeType>.CellConfigurator) {
        tableView.register(CellType.self, forCellReuseIdentifier: CellType.ID)
        dataManager = TreeDataManager(tableView: tableView, depthPadding: depthPadding, cellConfigurator: cellConfigurator)
        self.depthPadding = depthPadding
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(_ tree: Tree<NodeType>, shouldAnimate: Bool = true) {
        dataManager.render(tree, shouldAnimate: shouldAnimate)
    }
    
    override func loadView() {
        self.view = UIView()
        setupLayout()
        tableView.addSubview(hintView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var items = [UIDragItem]()
        
        guard let nodeCell = (tableView.cellForRow(at: indexPath)) as? CellType,
            let node = nodeCell.node else {
                return []
        }
        // Hiding any visible children for drag interaction
        lastAreChildrenHiddenState = node.areChildrenHidden
        node.areChildrenHidden = true
        nodeCell.renderTree()
        
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = node
        
        
        // Total number of nodes under the dragged item plus the dragged item
        let draggedItemCount = node.count + 1
        for _ in 1...draggedItemCount {
            let dragItem = UIDragItem(itemProvider: NSItemProvider())
            dragItem.localObject = node
            
            items.append(dragItem)
        }
        
        return items
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        hintView.color = .clear
        xValueRangesVsDepthMap.removeAll()

        if lastAreChildrenHiddenState != lastInteractedCell?.node?.areChildrenHidden {
            lastInteractedCell?.node?.areChildrenHidden = lastAreChildrenHiddenState ?? false
            lastAreChildrenHiddenState = nil
            lastInteractedCell?.renderTree()
        }

        lastInteractedCell = nil
        lastDroppedIndexPath = nil
    }
    
    struct NodeReorderDetails {
        let draggedBareNode: BareNode
        let tempNodeOrder: [BareNode]
        let proposedDepth: Int
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        guard let destinationIndexPath = destinationIndexPath,
            let nodeCell = (tableView.cellForRow(at: destinationIndexPath)) as? CellType,
            let node = nodeCell.node else {
                return DropProposal.forbidden
        }

        let frame = CGRect(x: 0, y: CGFloat((destinationIndexPath.row) * 60), width: tableView.frame.width, height: 60)
        hintView.color = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        
        let sessionXvalue = session.location(in: tableView).x

        let draggedNode = session.items.first?.localObject as! NodeType
        let draggedBareNode = draggedNode.bareNode
        let tempNodeOrder = dataManager.getNodeOrder(whenNode: draggedNode, movesTo: destinationIndexPath)

        // Generating possible depth values that a node at this destination indexpath can have
        // This can be visualised by dragging the hint view towards right and the left
        if shouldGenerateXvalueRangeVsDepthMap(for: destinationIndexPath) {
            
            let previousNode = getNodeAtPosition(.previous, to: draggedNode.bareNode, nodes: tempNodeOrder)
        
            func getListNode(forBareNode bareNode: BareNode?) -> NodeType? {
                return tableView.visibleCells.compactMap {
                    $0 as? CellType
                }.first {
                    $0.node?.ID == bareNode?.ID
                }?.node
            }

            print("PREV NODe \(String(describing: (getListNode(forBareNode: previousNode) as? List)?.name))")

            let hintViewDepth = getHintViewDepth(previousNode: previousNode)
            
            print("HINT VIEW DEPTH \(hintViewDepth)")
            
            print("MAX DEPTH ->>>>\(draggedNode.maxDepth)")
            
            let leastPossibleDepth = computeLeastPossibleDepth(hintViewDepth: hintViewDepth,
                                                               draggedNode: draggedBareNode,
                                                               updatedNodeList: tempNodeOrder)
            
            generateXvalueRangeVsDepthMap(leastPossibleDepth: leastPossibleDepth,
                                          hintViewDepth: hintViewDepth,
                                          sessionXvalue: sessionXvalue,
                                          previousNode: previousNode)


            lastInteractedCell = nodeCell
            lastDroppedIndexPath = destinationIndexPath

            hintView.frame = frame
            hintView.leadingConstant = CGFloat(hintViewDepth) * depthPadding

            session.localDragSession?.localContext = NodeReorderDetails(draggedBareNode: draggedBareNode,
                                                                        tempNodeOrder: tempNodeOrder,
                                                                        proposedDepth: hintViewDepth)
            
            return DropProposal.insert
        }

        let depthForSessionXvalue = xValueRangesVsDepthMap.first { rangeAndDepth in
            return rangeAndDepth.key.contains(sessionXvalue)
            }?.value

        guard depthForSessionXvalue != nil else {
            return DropProposal.insert
        }

        let leadingConstant = CGFloat(depthForSessionXvalue!) * depthPadding

        guard hintView.leadingConstant != leadingConstant else { return DropProposal.insert }
        hintView.leadingConstant = leadingConstant

        session.localDragSession?.localContext = NodeReorderDetails(draggedBareNode: draggedBareNode,
                                                                    tempNodeOrder: tempNodeOrder,
                                                                    proposedDepth: depthForSessionXvalue!)

        return DropProposal.insert
        
    }
    
    
    private func getMaxPossibleDepth() {
        
    }
    
    
    private func computeLeastPossibleDepth(hintViewDepth: Int, draggedNode: BareNode, updatedNodeList: [BareNode]) -> Int {
        let leastPossibleDepth = hintViewDepth
        
        // There is no parent
        // Zero depth
        guard let parentNode = getParentNode(for: draggedNode, tempNodeOrder: updatedNodeList) else {
            return leastPossibleDepth
        }
        
        // There is no next node, so free to go to the lowest depth
        // without disturbing the parent-child relationships of other nodes
        guard let nextNode = getNodeAtPosition(.next, to: draggedNode, nodes: updatedNodeList) else {
            return 0
        }
        
        //        print("NEXT NODE \(nextNode.n)")
        
        // Making sure that the next node is not the child of the dragged node's parent
        guard parentNode.children.contains(nextNode) == false else {
            return leastPossibleDepth
        }
        
        // Getting the parent node of type -> NodeType
        // Bare Nodees do not hold reference to their parents
        guard let parentTreeNode = dataManager.node(withID: parentNode.ID) else {
            return leastPossibleDepth
        }
        
        // Subtracting one since if the code reaches here it means that the dragged node
        // is the last child. So, it can go one level lower than its current one
        return getLeastPossibleDepth(for: parentTreeNode, currentDepth: draggedNode.depth) - 1
    }
    
    
    private func getParentNode(for draggedNode: BareNode, tempNodeOrder: [BareNode]) -> BareNode? {
        let index = tempNodeOrder.firstIndex{ $0.ID == draggedNode.ID }
        let nodeSearchSpace = tempNodeOrder[0...index!].reversed()
        
        return nodeSearchSpace.first {
            $0.depth < draggedNode.depth
        }
    }
    
    enum NodePosition {
        case next
        case previous
    }
    
    private func getNodeAtPosition(_ position: NodePosition, to relativeNode: BareNode, nodes: [BareNode]) -> BareNode? {
        guard let relativeNodeIndex = nodes.firstIndex(where: { $0.ID == relativeNode.ID }) else {
            return nil
        }
        
        var positionIndex = 0
        
        switch position {
        case .next:
            positionIndex = relativeNodeIndex + 1
        case .previous:
            positionIndex = relativeNodeIndex - 1
        }
    
        return nodes.validIndexRange.contains(positionIndex) ? nodes[positionIndex] : nil
    }

    
    private func getHintViewDepth(previousNode: BareNode?) -> Int {
        guard let previousNode = previousNode else { return 0 }
        
        if previousNode.hasChildren {
            return previousNode.depth + 1
        }
        
        return previousNode.depth
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        
        guard let dragItem = coordinator.items.first?.dragItem,
              let nodeReorderDetails = coordinator.session.localDragSession?.localContext as? NodeReorderDetails else {
                return
        }

        dataManager.reorderNode(using: nodeReorderDetails)
        coordinator.drop(dragItem, toRowAt: destinationIndexPath)
    }
}


extension TreeView {
    
    // Every node can go one depth lower than its current depth when it satisfies the following condition,
    // It is the last child of its parent.
    
    // If its the last child, we subtract the current depth by one and check it its parent also satisfies the abbove condition
    // We keep doing this until there is no parent or when the node stops being the last child of its parent
    private func getLeastPossibleDepth(for node: NodeType, currentDepth: Int) -> Int {
        guard let parent = node.parent else { return currentDepth }
        if parent.children.last! == node {
            return getLeastPossibleDepth(for: parent, currentDepth: currentDepth - 1)
        } else {
            return currentDepth
        }
    }
    
    
    private func shouldGenerateXvalueRangeVsDepthMap(for indexPath: IndexPath) -> Bool {
        return lastDroppedIndexPath != indexPath || lastDroppedIndexPath == nil
    }
    
    
    private func getStartXvalueForPreviousDepth(previousDepth: Int) -> CGFloat {
        xValueRangesVsDepthMap.first { range, depth in
            return depth == previousDepth
            }!.key.lowerBound
    }
    
    private func generateXvalueRangeVsDepthMap(leastPossibleDepth: Int,
                                               hintViewDepth: Int,
                                               sessionXvalue: CGFloat,
                                               previousNode: BareNode?) {
        
        let startXvalueForHintViewDepth = sessionXvalue - (distanceBetweenHintViewDepthsInXaxis / 2)
        let endXvalueForHintViewDepth = sessionXvalue + (distanceBetweenHintViewDepthsInXaxis / 2)
        
        var depthOffsetFromOrginalPoint = 1
        var currentDepth = hintViewDepth - 1
        var startXvalueForPreviousDepth: CGFloat?
        
        xValueRangesVsDepthMap.removeAll()
        
        // Mapping X Value ranges and depths, left to the session point
        while currentDepth >= leastPossibleDepth {
            
            let endXvalue = startXvalueForPreviousDepth ?? startXvalueForHintViewDepth
            
            if currentDepth == 0 {
                xValueRangesVsDepthMap[0...endXvalue] = currentDepth
            } else {
                let startXvalue = startXvalueForHintViewDepth - (CGFloat(depthOffsetFromOrginalPoint) * distanceBetweenHintViewDepthsInXaxis)
                xValueRangesVsDepthMap[startXvalue...endXvalue] = currentDepth
                startXvalueForPreviousDepth = startXvalue
            }
            
            currentDepth -= 1
            depthOffsetFromOrginalPoint += 1
        }
        
        
        // Mapping Current depth and X range
        xValueRangesVsDepthMap[startXvalueForHintViewDepth...endXvalueForHintViewDepth] = hintViewDepth
        
        // Deciding whether the node can have depth of currentDepth + 1
        // The previous node CANNOT
        // 1) have a lesser depth (then it would be already a parent to current node)
        // 2) greater depth (which is invalid becasue previous node should always have a depth lesser than or equal to current node)
        guard let previousNode = previousNode, hintViewDepth == previousNode.depth else {
            return
        }
        
        // Sometimes the user might start the drag, from the extreme right which requires this check
        guard tableView.frame.maxX > endXvalueForHintViewDepth else {
            return
        }
        
        xValueRangesVsDepthMap[endXvalueForHintViewDepth...tableView.frame.maxX] = hintViewDepth + 1
        
    }
}

// Drag state did change inside cell subclass -> Custom appearance while drag and drop
// UIDropProposal -> To insert cells into a new place or insert into other items -> Create parent-child relationships
// ItemAddingTo -> Add multiple items to drag
// UISpringLoading -> To navigate screens with dragged item
// coordinator.drop -> To provide animations while droppping

extension Int {
    func percent(of value: CGFloat) -> CGFloat {
        return (value * CGFloat(self)) / 100
    }
}

struct DropProposal {
    static let insert = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    static let forbidden = UITableViewDropProposal(operation: .forbidden)
    static let cancel = UITableViewDropProposal(operation: .cancel)
}
