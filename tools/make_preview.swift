// Cut an App Store preview video from a screen recording.
//
// Usage: swiftc -O make_preview.swift -o make_preview
//        ./make_preview <in.mov> <out.mov> <start-end> [<start-end> ...]
//
// Joins the given sections (in seconds), scales to 886 × 1920 (the iPhone app preview size),
// sets 30 fps and keeps the stereo audio, exporting H.264. App previews must be 15–30 seconds.

import AVFoundation

let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: make_preview <in> <out> <start-end> ...")
    exit(1)
}
let source = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let outURL = URL(fileURLWithPath: args[2])
let sections: [(Double, Double)] = args[3...].map {
    let p = $0.split(separator: "-").map { Double($0)! }
    return (p[0], p[1])
}
let renderSize = CGSize(width: 886, height: 1920)

let comp = AVMutableComposition()
let srcVideo = source.tracks(withMediaType: .video)[0]
let srcAudio = source.tracks(withMediaType: .audio).first
let video = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
let audio = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

var cursor = CMTime.zero
for (start, end) in sections {
    let range = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                            end: CMTime(seconds: end, preferredTimescale: 600))
    try! video.insertTimeRange(range, of: srcVideo, at: cursor)
    if let srcAudio { try! audio.insertTimeRange(range, of: srcAudio, at: cursor) }
    cursor = cursor + range.duration
}
print("duration", CMTimeGetSeconds(cursor))

// Scale to cover 886 × 1920, centred; the source is 1082 × 2340, almost the same shape.
let natural = srcVideo.naturalSize.applying(srcVideo.preferredTransform)
let size = CGSize(width: abs(natural.width), height: abs(natural.height))
let scale = max(renderSize.width / size.width, renderSize.height / size.height)
let dx = (renderSize.width - size.width * scale) / 2
let dy = (renderSize.height - size.height * scale) / 2
let transform = srcVideo.preferredTransform
    .concatenating(CGAffineTransform(scaleX: scale, y: scale))
    .concatenating(CGAffineTransform(translationX: dx, y: dy))

let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: video)
layer.setTransform(transform, at: .zero)
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: cursor)
instruction.layerInstructions = [layer]
let videoComp = AVMutableVideoComposition()
videoComp.renderSize = renderSize
videoComp.frameDuration = CMTime(value: 1, timescale: 30)
videoComp.instructions = [instruction]

try? FileManager.default.removeItem(at: outURL)
let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality)!
export.outputURL = outURL
export.outputFileType = .mov
export.videoComposition = videoComp
let done = DispatchSemaphore(value: 0)
export.exportAsynchronously { done.signal() }
done.wait()
if let error = export.error {
    print("export failed:", error)
    exit(1)
}
print("wrote", outURL.path)
