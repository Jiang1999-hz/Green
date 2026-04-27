import Foundation

struct GrowthTheme: Identifiable, Equatable, Sendable {
    enum Kind: String, CaseIterable, Identifiable, Sendable {
        case defaultGarden
        case bloomGlow

        var id: String { rawValue }

        var title: String {
            switch self {
            case .defaultGarden:
                return "默认花园"
            case .bloomGlow:
                return "晨光花房"
            }
        }

        var subtitle: String {
            switch self {
            case .defaultGarden:
                return "柔和的园艺风格，适合当前默认成长页。"
            case .bloomGlow:
                return "更轻盈的花朵主题，强调花苞到盛放的阶段变化。"
            }
        }
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let isPremium: Bool

    var id: Kind { kind }

    static let `default` = GrowthTheme(
        kind: .defaultGarden,
        title: Kind.defaultGarden.title,
        subtitle: Kind.defaultGarden.subtitle,
        isPremium: false
    )

    static let bloomGlow = GrowthTheme(
        kind: .bloomGlow,
        title: Kind.bloomGlow.title,
        subtitle: Kind.bloomGlow.subtitle,
        isPremium: false
    )

    static let builtInThemes: [GrowthTheme] = [
        .default,
        .bloomGlow
    ]
}
