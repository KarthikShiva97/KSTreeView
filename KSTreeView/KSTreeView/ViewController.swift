//
//  ViewController.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 13/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import UIKit

class ListCell: TreeCell<List> {
    
    let name: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        return label
    }()
    
    private let icon : UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)
        button.setImage(UIImage(named: "arrow"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    private var widthConstraint: NSLayoutConstraint? {
        didSet {
            widthConstraint?.isActive = true
        }
    }
    
    func setup() {
        if node!.hasChildren {
            widthConstraint?.constant = 20
            toggleButton.transform = .identity
            toggleButton.transform = self.toggleButton.transform.rotated(by: -(.pi / 2))
            icon.image = UIImage(named: "folder")
        } else {
            widthConstraint?.constant = 0
            icon.image = UIImage(named: "list")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        treeCellContentView.layer.masksToBounds = true
        treeCellContentView.layer.cornerRadius = 10
    }
    
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "")
        treeCellContentView.backgroundColor = #colorLiteral(red: 0.09411764706, green: 0.09411764706, blue: 0.09803921569, alpha: 1)
        treeCellContentView.addSubview(name)
        treeCellContentView.addSubview(toggleButton)
        treeCellContentView.addSubview(icon)
        
        icon.leadingAnchor.constraint(equalTo: treeCellContentView.leadingAnchor, constant: 20).isActive = true
        icon.topAnchor.constraint(equalTo: treeCellContentView.topAnchor).isActive = true
        icon.bottomAnchor.constraint(equalTo: treeCellContentView.bottomAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        name.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 20).isActive = true
        name.trailingAnchor.constraint(equalTo: toggleButton.trailingAnchor).isActive = true
        name.topAnchor.constraint(equalTo: treeCellContentView.topAnchor).isActive = true
        name.bottomAnchor.constraint(equalTo: treeCellContentView.bottomAnchor).isActive = true
        
        toggleButton.trailingAnchor.constraint(equalTo: treeCellContentView.trailingAnchor,
                                               constant: -30).isActive = true
        toggleButton.topAnchor.constraint(equalTo: treeCellContentView.topAnchor).isActive = true
        toggleButton.bottomAnchor.constraint(equalTo: treeCellContentView.bottomAnchor).isActive = true
        widthConstraint = toggleButton.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint?.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight() {
        UIView.animate(withDuration: 0.5) {
            self.treeCellContentView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        }
    }
    
    func unHighlight() {
        UIView.animate(withDuration: 0.5) {
            self.treeCellContentView.backgroundColor = #colorLiteral(red: 0.09411764706, green: 0.09411764706, blue: 0.09803921569, alpha: 1)

        }
    }
    
    @objc func handleToggle() {
        UIView.animate(withDuration: 0.2, animations: {
            if self.node!.areChildrenHidden {
                self.toggleButton.transform = self.toggleButton.transform.rotated(by: (.pi / 2))
            } else {
                self.toggleButton.transform = self.toggleButton.transform.rotated(by: -(.pi / 2))
            }
        }) { (didFinish) in
            self.toggleShowHideChildren()
        }
    }
}

final class List: TreeNode {
    let ID: UUID
    var tree: Tree<List>?
    var parent: List?
    var children: [List] = []
    var areChildrenHidden: Bool = true
    var name: String

    init(name: String) {
        self.name = name
        self.ID = UUID()
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let treeView = TreeView<ListCell, List>{ (listCell, list) -> (ListCell) in
            listCell.name.text = list.name
            listCell.setup()
            return listCell
        }
        
        treeView.view.translatesAutoresizingMaskIntoConstraints = false
        add(treeView)
        treeView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        treeView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        treeView.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        treeView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        
        let a = List(name: "A")
        
        let b = List(name: "B")
        let b1 = List(name: "B1")
        let b2 = List(name: "B2")
        
        let c = List(name: "C")
        let c1 = List(name: "C1")
        let c2 = List(name: "C2")
        
        let d = List(name: "D")
        let e = List(name: "E")
        let f = List(name: "F")
        
        a.addChildren([b,c])
        a.areChildrenHidden = false
        
        b.addChildren([b1, b2])
        b.areChildrenHidden = false
        
        c.addChildren([c1, c2])
        c.areChildrenHidden = false
        
        d.addChild(e)
        d.areChildrenHidden = false
        
        e.addChild(f)
        e.areChildrenHidden = false
        
        let tree = Tree<List>(children: [a, d])!
        treeView.render(tree, shouldAnimate: false)
    }
}


@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        
        if let frame = frame {
            child.view.frame = frame
        }
        
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
