//
//  Parameters.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/08/01.
//

import Foundation

let directoryName = "Frame"

struct Parameters: Codable {
    var frameNumber: Int
    var intrinsic: simd_float3x3
    var viewMatrix: simd_float4x4
    var depthMap: DepthMap
    
    init() {
        frameNumber = 0
        intrinsic = simd_float3x3()
        viewMatrix = simd_float4x4()
        depthMap = DepthMap()
    }
    
    enum CodingKeys: String, CodingKey {
        case frameNumber = "frame_number"
        case intrinsic
        case viewMatrix = "view_matrix"
        case depthMap = "depth_map"
    }
    
    func getURL(directoryID: Int) -> URL {
        guard let root = ViewController.rootDirectory else { fatalError() }
        let directory = root.appendingPathComponent(directoryName, isDirectory: true)
        let url = directory.appendingPathComponent("frame_\(frameNumber)").appendingPathExtension("json")
        return url
    }
    
    func save(jsonEncoder: JSONEncoder, url: URL) async throws -> () {
        let jsonData = try jsonEncoder.encode(self)
        try jsonData.write(to: url, options: .noFileProtection)
    }
}


class DepthMap: Codable {
    var width: Int
    var height: Int
    var values: [Float32]
    
    init() {
        width = 0
        height = 0
        values = []
    }
    
    func update(width: Int, height: Int, values: [Float32]) {
        self.width = width
        self.height = height
        self.values = values
    }
}
