//
//  TreeCell.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 14/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import UIKit

class TreeCell<NodeType: TreeNode>: UITableViewCell {
    
    /// This is the node object associated with the cell
    /// You don't need to store your node object in your tree cell subclass
    final var node: NodeType? {
        return data?.node
    }
    
    /// This is the place where all your subviews and constraints go. Do not add your subviews onto the cell or the content view
    final var treeCellContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var data: TreeCellData?
    
    private var delegate: TreeCellDelegate? {
        return data?.delegate
    }
    
    private var depthPadding: CGFloat = 0 {
        didSet {
            leadingConstraint?.constant = depthPadding
        }
    }
    
    private var leadingConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "")
        backgroundColor = .black
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.addSubview(treeCellContentView)
        treeCellContentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        treeCellContentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        treeCellContentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        leadingConstraint = treeCellContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leadingConstraint?.isActive = true
    }
    
    @objc func toggleShowHideChildren() {
        guard let node = node else { return }
        node.areChildrenHidden = !node.areChildrenHidden
        delegate?.renderTree()
    }
}


extension TreeCell {
    func configure(with cellData: TreeCellData) {
        self.data = cellData
        self.depthPadding = CGFloat(node!.depth) * cellData.depthPadding
    }
    
    func showChildren() {
        node?.areChildrenHidden = false
        delegate?.renderTree()
    }
    
    func hideChildren() {
        node?.areChildrenHidden = true
        delegate?.renderTree()
    }
     
    func shuffleChildren() {
        node?.children.shuffle()
        delegate?.renderTree()
    }
    
    func renderTree() {
        delegate?.renderTree()
    }
}

extension TreeCell {
    struct TreeCellData {
        let node: NodeType
        let depthPadding: CGFloat
        let delegate: TreeCellDelegate
    }
}

extension UITableViewCell {
    static var ID: String {
        return "ID"
    }
}
