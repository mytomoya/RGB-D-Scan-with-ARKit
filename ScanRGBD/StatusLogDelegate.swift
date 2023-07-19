//
//  StatusLogDelegate.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2023/04/01.
//

import Foundation

protocol StatusLogDelegate {
    var totalFrames: Int { get set }
    var savedFrames: Int { get set }

    func incrementTotalFrames()
    func incrementSavedFrames()
}
