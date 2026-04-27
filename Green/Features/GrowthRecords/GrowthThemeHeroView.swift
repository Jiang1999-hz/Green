import SwiftUI

struct GrowthThemeHeroView: View {
    let stage: GrowthJourneyStage
    let theme: GrowthTheme

    var body: some View {
        Group {
            switch theme.kind {
            case .defaultGarden:
                DefaultGardenGrowthHero(stage: stage)
            case .bloomGlow:
                BloomGlowGrowthHero(stage: stage)
            }
        }
    }
}

private struct DefaultGardenGrowthHero: View {
    let stage: GrowthJourneyStage

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.primary.opacity(0.08))
                .frame(height: 250)

            VStack(spacing: 0) {
                ZStack {
                    if stage.currentStageIndex >= 4 {
                        flowerPetals
                    }

                    if stage.currentStageIndex >= 3 {
                        branchingLeaves
                    }

                    if stage.currentStageIndex >= 2 {
                        midLeaves
                    }

                    if stage.currentStageIndex >= 1 {
                        sproutLeaves
                    }

                    stem
                }
                .frame(height: 190)

                potBase
            }
            .padding(.bottom, 18)
        }
    }

    private var stem: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppTheme.primary)
            .frame(width: 14, height: stemHeight)
            .overlay(alignment: .top) {
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 20, height: 20)
                    .offset(y: -6)
            }
    }

    private var sproutLeaves: some View {
        HStack(spacing: 48) {
            leaf(angle: -34, width: 42, height: 68)
            leaf(angle: 34, width: 42, height: 68)
        }
        .offset(y: 18)
    }

    private var midLeaves: some View {
        HStack(spacing: 92) {
            leaf(angle: -50, width: 52, height: 82)
            leaf(angle: 50, width: 52, height: 82)
        }
        .offset(y: -10)
    }

    private var branchingLeaves: some View {
        HStack(spacing: 132) {
            leaf(angle: -58, width: 58, height: 88)
            leaf(angle: 58, width: 58, height: 88)
        }
        .offset(y: -40)
    }

    private var flowerPetals: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.80, blue: 0.52))
                    .frame(width: 30, height: 56)
                    .offset(y: -18)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .fill(Color(red: 0.93, green: 0.58, blue: 0.22))
                .frame(width: 28, height: 28)
        }
        .offset(y: -76)
    }

    private var potBase: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.78, green: 0.58, blue: 0.44))
                .frame(width: 120, height: 22)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.69, green: 0.47, blue: 0.34))
                .frame(width: 96, height: 54)
        }
    }

    private func leaf(angle: Double, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width / 2, style: .continuous)
            .fill(AppTheme.primary.opacity(0.94))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle))
            .shadow(color: AppTheme.primary.opacity(0.12), radius: 10, y: 8)
    }

    private var stemHeight: CGFloat {
        switch stage.currentStageIndex {
        case 0:
            return 46
        case 1:
            return 72
        case 2:
            return 102
        case 3:
            return 132
        default:
            return 146
        }
    }
}

private struct BloomGlowGrowthHero: View {
    let stage: GrowthJourneyStage

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.93),
                            Color(red: 0.98, green: 0.87, blue: 0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 250)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 168, height: 168)
                .blur(radius: 4)
                .offset(y: -16)

            VStack(spacing: 0) {
                ZStack {
                    if stage.currentStageIndex >= 3 {
                        glowHalo
                    }

                    if stage.currentStageIndex >= 4 {
                        outerPetals
                    }

                    if stage.currentStageIndex >= 2 {
                        innerPetals
                    }

                    stem
                    budCore
                    baseLeaves
                }
                .frame(height: 194)

                vaseBase
            }
            .padding(.bottom, 18)
        }
    }

    private var stem: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(red: 0.32, green: 0.60, blue: 0.34))
            .frame(width: 12, height: stemHeight)
            .offset(y: 18)
    }

    private var budCore: some View {
        Circle()
            .fill(budColor)
            .frame(width: budSize, height: budSize)
            .overlay {
                if stage.currentStageIndex >= 2 {
                    Circle()
                        .stroke(Color.white.opacity(0.32), lineWidth: 3)
                        .frame(width: budSize * 0.72, height: budSize * 0.72)
                }
            }
            .offset(y: budOffsetY)
            .shadow(color: budColor.opacity(0.22), radius: 12, y: 8)
    }

    private var innerPetals: some View {
        ZStack {
            petalLayer(count: 4, radius: 26, width: 24, height: 54, color: Color(red: 0.99, green: 0.73, blue: 0.56))
            petalLayer(count: 4, radius: 18, width: 20, height: 44, color: Color(red: 1.0, green: 0.84, blue: 0.68))
        }
        .offset(y: -46)
        .opacity(stage.currentStageIndex >= 4 ? 1 : 0.78)
    }

    private var outerPetals: some View {
        petalLayer(count: 6, radius: 40, width: 28, height: 68, color: Color(red: 1.0, green: 0.88, blue: 0.78))
            .offset(y: -56)
    }

    private var glowHalo: some View {
        Circle()
            .fill(Color.white.opacity(0.34))
            .frame(width: 128, height: 128)
            .blur(radius: 14)
            .offset(y: -40)
    }

    private var baseLeaves: some View {
        HStack(spacing: 54) {
            leaf(angle: -34, width: 34, height: 58)
            leaf(angle: 34, width: 34, height: 58)
        }
        .offset(y: 38)
    }

    private var vaseBase: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.94, green: 0.72, blue: 0.58))
                .frame(width: 112, height: 20)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(red: 0.86, green: 0.57, blue: 0.46))
                .frame(width: 82, height: 56)
        }
    }

    private func petalLayer(count: Int, radius: CGFloat, width: CGFloat, height: CGFloat, color: Color) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                RoundedRectangle(cornerRadius: width / 2, style: .continuous)
                    .fill(color)
                    .frame(width: width, height: height)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(count))))
            }
        }
    }

    private func leaf(angle: Double, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width / 2, style: .continuous)
            .fill(Color(red: 0.46, green: 0.73, blue: 0.40))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle))
    }

    private var stemHeight: CGFloat {
        switch stage.currentStageIndex {
        case 0:
            return 52
        case 1:
            return 74
        case 2:
            return 98
        case 3:
            return 116
        default:
            return 126
        }
    }

    private var budSize: CGFloat {
        switch stage.currentStageIndex {
        case 0:
            return 24
        case 1:
            return 30
        case 2:
            return 40
        case 3:
            return 48
        default:
            return 54
        }
    }

    private var budOffsetY: CGFloat {
        switch stage.currentStageIndex {
        case 0:
            return -10
        case 1:
            return -18
        case 2:
            return -28
        case 3:
            return -36
        default:
            return -40
        }
    }

    private var budColor: Color {
        switch stage.currentStageIndex {
        case 0, 1:
            return Color(red: 0.95, green: 0.70, blue: 0.56)
        case 2, 3:
            return Color(red: 0.98, green: 0.62, blue: 0.48)
        default:
            return Color(red: 0.99, green: 0.68, blue: 0.44)
        }
    }
}
