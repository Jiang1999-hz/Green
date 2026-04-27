import Foundation

struct GrowthJourneyStage: Equatable, Sendable {
    enum Kind: Int, CaseIterable, Equatable, Sendable {
        case seedling
        case sprout
        case youngPlant
        case branching
        case bloom

        var title: String {
            switch self {
            case .seedling:
                return "发芽期"
            case .sprout:
                return "幼苗期"
            case .youngPlant:
                return "展叶期"
            case .branching:
                return "繁茂期"
            case .bloom:
                return "盛放期"
            }
        }

        var subtitle: String {
            switch self {
            case .seedling:
                return "刚开始建立成长轨迹。"
            case .sprout:
                return "记录逐渐稳定，正在长出第一层叶片。"
            case .youngPlant:
                return "生长轮廓已经清晰，进入更明显的变化期。"
            case .branching:
                return "枝叶开始变得丰盛，成长节奏很稳定。"
            case .bloom:
                return "已经形成完整的成长档案，可以回看清晰的阶段变化。"
            }
        }

        var symbolName: String {
            switch self {
            case .seedling:
                return "leaf"
            case .sprout:
                return "leaf.circle"
            case .youngPlant:
                return "leaf.fill"
            case .branching:
                return "tree"
            case .bloom:
                return "camera.macro"
            }
        }
    }

    struct Milestone: Equatable, Sendable {
        let kind: Kind
        let requiredRecordCount: Int
    }

    static let milestones: [Milestone] = [
        Milestone(kind: .seedling, requiredRecordCount: 1),
        Milestone(kind: .sprout, requiredRecordCount: 3),
        Milestone(kind: .youngPlant, requiredRecordCount: 6),
        Milestone(kind: .branching, requiredRecordCount: 10),
        Milestone(kind: .bloom, requiredRecordCount: 15)
    ]

    let kind: Kind
    let recordCount: Int
    let currentStageIndex: Int
    let nextMilestoneRecordCount: Int?
    let remainingRecordCountToNextStage: Int?

    init(recordCount: Int) {
        self.recordCount = recordCount

        let resolvedMilestone = Self.milestones.last { recordCount >= $0.requiredRecordCount } ?? Self.milestones[0]
        self.kind = resolvedMilestone.kind
        self.currentStageIndex = resolvedMilestone.kind.rawValue

        if let nextMilestone = Self.milestones.first(where: { $0.requiredRecordCount > recordCount }) {
            nextMilestoneRecordCount = nextMilestone.requiredRecordCount
            remainingRecordCountToNextStage = nextMilestone.requiredRecordCount - recordCount
        } else {
            nextMilestoneRecordCount = nil
            remainingRecordCountToNextStage = nil
        }
    }

    var progressLabel: String {
        if let remainingRecordCountToNextStage {
            return "再记录 \(remainingRecordCountToNextStage) 次，进入下一阶段"
        }

        return "成长档案已经进入当前阶段的完整形态"
    }

    var supportLabel: String {
        "已记录 \(recordCount) 次成长瞬间"
    }
}
