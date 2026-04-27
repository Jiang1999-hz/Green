import Foundation

struct GrowthAnimationDescriptor: Equatable, Sendable {
    let plantName: String
    let recordCount: Int
    let daysSincePlanted: Int
    let themeKind: GrowthTheme.Kind

    var introTitle: String {
        plantName
    }

    var introSubtitle: String {
        "成长回顾"
    }

    var introDetail: String {
        "已记录 \(recordCount) 次成长瞬间"
    }

    var outroTitle: String {
        "继续记录下一次变化"
    }

    var outroSubtitle: String {
        "种植 \(daysSincePlanted) 天"
    }

    var outroDetail: String {
        "Green 为你整理这株植物的成长轨迹"
    }
}
