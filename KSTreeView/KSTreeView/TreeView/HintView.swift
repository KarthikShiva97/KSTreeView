//
//  HintView.swift
//  LivePreviews
//
//  Created by Kalyani shiva on 28/12/19.
//  Copyright © 2019 Kalyani shiva. All rights reserved.
//

import UIKit

class HintView: UIView {
    
    var color: UIColor = .blue {
        didSet {
            visibleView.backgroundColor = color
        }
    }
    
    var leadingConstant: CGFloat = 0 {
        didSet {
            UIView.animate(withDuration: 0.1, animations: {
                self.leadingConstraint?.constant = self.leadingConstant
            }) { (didEnd) in
                self.feedbackGenerator.selectionChanged()
            }
        }
    }
    
    private let visibleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .blue
        return view
    }()
    
    
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private var leadingConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        visibleView.layer.masksToBounds = true
        visibleView.layer.cornerRadius = 10
    }
    
    private func setupLayout() {
        addSubview(visibleView)
        visibleView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        visibleView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        visibleView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        leadingConstraint = visibleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leadingConstraint?.isActive = true
    }
}
