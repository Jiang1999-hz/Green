import Foundation

@MainActor
protocol GrowthThemePreferenceStore {
    func selectedThemeKind() -> GrowthTheme.Kind
    func setSelectedThemeKind(_ kind: GrowthTheme.Kind)
}

struct UserDefaultsGrowthThemePreferenceStore: GrowthThemePreferenceStore {
    private let userDefaults: UserDefaults
    private let key = "growth_theme_kind"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func selectedThemeKind() -> GrowthTheme.Kind {
        guard let rawValue = userDefaults.string(forKey: key),
              let kind = GrowthTheme.Kind(rawValue: rawValue) else {
            return .defaultGarden
        }

        return kind
    }

    func setSelectedThemeKind(_ kind: GrowthTheme.Kind) {
        userDefaults.set(kind.rawValue, forKey: key)
    }
}
