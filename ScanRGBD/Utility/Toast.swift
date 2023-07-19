//
//  Toast.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/10/24.
//

import UIKit

func toast(_ text: String, _ parent: UIView) {
    let label = UILabel()
    let width = parent.frame.size.width
    let height = parent.frame.size.height / 15
    let bottomPadding = parent.frame.size.height / 2
    
    label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    label.textColor = UIColor.white
    label.textAlignment = .center;
    label.text = text
    
    label.frame = CGRect(x: parent.frame.size.width / 2 - (width / 2),
                         y: parent.frame.size.height - height - bottomPadding,
                         width: width,
                         height: height)
    parent.addSubview(label)
    
    UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut, animations: {
        label.alpha = 0.0
    }, completion: { _ in
        label.removeFromSuperview()
    })
}
