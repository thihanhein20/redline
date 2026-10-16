import Foundation

/// A full `metal-HUD: frames,a,b,interval,gpu,interval,gpu,…` line, as Apple's HUD prints it to the
/// output of games Redline launches. The pairs are (frame interval ms, GPU time ms) for recent frames.
struct HUDFrameReport: Equatable {
    var frameIntervalsMS: [Double]
    var gpuTimesMS: [Double]

    static func parse(_ line: String) -> HUDFrameReport? {
        guard let range = line.range(of: "metal-HUD:") else { return nil }
        let fields = line[range.upperBound...].split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard fields.count >= 5 else { return nil }
        let pairs = fields.dropFirst(3)
        let values = pairs.compactMap { $0 }
        guard values.count == pairs.count, values.count.isMultiple(of: 2) else { return nil }
        return HUDFrameReport(
            frameIntervalsMS: stride(from: 0, to: values.count, by: 2).map { values[$0] },
            gpuTimesMS: stride(from: 1, to: values.count, by: 2).map { values[$0] }
        )
    }

    /// Typical GPU time per frame across the reported frames.
    var medianGPUTimeMS: Double? {
        gpuTimesMS.isEmpty ? nil : gpuTimesMS.sorted()[gpuTimesMS.count / 2]
    }
}
