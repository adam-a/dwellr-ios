//
//  VideoUtils.swift
//  Dwellr
//
//  Created by Adam Ali on 8/13/23.
//

import Foundation
import AVFoundation
import UIKit


func tempURLForVideo() -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileName = UUID().uuidString + ".mov"
    return tempDirectory.appendingPathComponent(fileName)
}

func mergeVideos(captureData:[CaptureData], outputURL: URL, completion: @escaping (URL?, Error?) -> Void)  {

    var assets: [AVAsset] = []

    for captureDatum in captureData {
        let avAsset = AVAsset(url: captureDatum.url) as AVAsset
        assets.append(avAsset)
    }

    let composition = AVMutableComposition()
    guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(nil, NSError(domain: "VideoMergeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create video track."]))
        return
    }

    guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(nil, NSError(domain: "AudioMergeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio track."]))
        return
    }

    var time = CMTime.zero

    for asset in assets {
        let assetVideoTrack = asset.tracks(withMediaType: .video).first
        if let preferredTransform = assetVideoTrack?.preferredTransform {
            videoTrack.preferredTransform = preferredTransform
        }

        if let assetVideoTrack = assetVideoTrack {
            do {
                try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetVideoTrack, at: time)
            } catch {
                completion(nil, error)
                return
            }
        }

        // Audio track
        if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
            do {
                try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetAudioTrack, at: time)
            } catch {
                completion(nil, error)
                return
            }
        }

        time = CMTimeAdd(time, asset.duration)

    }


    let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
    exportSession?.outputURL = outputURL
    exportSession?.outputFileType = .mp4


    exportSession?.exportAsynchronously(completionHandler: {
        switch exportSession?.status {
        case .completed:
            completion(outputURL, nil)
        case .failed:
            if let error = exportSession?.error {
                print("Export failed with error: \(error)")
                completion(nil, error)
            } else {
                let unknownError = NSError(domain: "VideoMergeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to merge videos."])
                print("Unknown error: \(unknownError)")
                completion(nil, unknownError)
            }
        default:
            let unknownError = NSError(domain: "VideoMergeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to merge videos."])
            print("Unknown error: \(unknownError)")
            completion(nil, unknownError)
        }
    })
}
