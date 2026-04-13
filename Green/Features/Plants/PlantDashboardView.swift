import CoreData
import SwiftUI

struct PlantDashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Plant.createdAt, ascending: false)],
        animation: .default
    )
    private var plants: FetchedResults<Plant>

    private let phases = MVPPhase.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    foundationsSection
                    roadmapSection
                    plantSnapshotSection
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Green")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("植物成长记录")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("MVP 基础工程已就绪。当前阶段只搭本地离线架构，不接任何 API，也不引入后端。")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.88))

            HStack(spacing: 10) {
                frameworkBadge("CoreData")
                frameworkBadge("PhotoKit")
                frameworkBadge("Vision")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.dark)
        )
    }

    private var foundationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("基础能力")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            VStack(spacing: 12) {
                foundationRow(
                    title: "本地存储",
                    detail: "植物主数据走 CoreData，后续照片只保存 PhotoKit asset identifier。"
                )
                foundationRow(
                    title: "权限策略",
                    detail: "相册读写和 Add Only 分开封装，兼容完整访问与部分访问两套逻辑。"
                )
                foundationRow(
                    title: "动画与识别",
                    detail: "AVFoundation 与 Vision 服务层已预留，后续继续按阶段接入。"
                )
            }
        }
    }

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("开发顺序")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            ForEach(phases) { phase in
                VStack(alignment: .leading, spacing: 6) {
                    Text(phase.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.dark)

                    Text(phase.detail)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.dark.opacity(0.76))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.86))
                )
            }
        }
    }

    private var plantSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("植物档案")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Spacer()

                Text("\(plants.count) 株")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.15), in: Capsule())
                    .foregroundStyle(AppTheme.primary)
            }

            if plants.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("还没有植物档案")
                        .font(.headline)
                        .foregroundStyle(AppTheme.dark)

                    Text("下一阶段会在这里接入植物档案 CRUD，包括名称、种类、摆放位置、种植日期、浇水频率和备注。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.dark.opacity(0.72))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.86))
                )
            } else {
                ForEach(plants) { plant in
                    plantRow(plant)
                }
            }
        }
    }

    private func frameworkBadge(_ name: String) -> some View {
        Text(name)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white)
    }

    private func foundationRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.dark)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(AppTheme.dark.opacity(0.72))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.86))
        )
    }

    private func plantRow(_ plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plant.wrappedName)
                .font(.headline)
                .foregroundStyle(AppTheme.dark)

            HStack(spacing: 12) {
                rowMeta("种植 \(plant.daysSincePlanted) 天")
                rowMeta(plant.wrappedLocation)
                rowMeta(plant.nextWateringLabel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.86))
        )
    }

    private func rowMeta(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.1), in: Capsule())
    }
}

private enum MVPPhase: String, CaseIterable, Identifiable {
    case plantCRUD
    case photoTimeline
    case wateringReminder
    case growthAnimation
    case fab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plantCRUD:
            return "1. 植物档案 CRUD"
        case .photoTimeline:
            return "2. 照片记录 + PhotoKit"
        case .wateringReminder:
            return "3. 浇水提醒 + UserNotifications"
        case .growthAnimation:
            return "4. 成长动画生成"
        case .fab:
            return "5. FAB 快捷入口"
        }
    }

    var detail: String {
        switch self {
        case .plantCRUD:
            return "先把植物主模型、列表、详情、编辑页和持久化走通。"
        case .photoTimeline:
            return "处理完整访问与部分访问两套相册权限流，再接成长记录时间线。"
        case .wateringReminder:
            return "在提醒阶段正式接入通知授权与调度，避免提前分散主线。"
        case .growthAnimation:
            return "视频导出固定放后台线程，主线程只做状态更新。"
        case .fab:
            return "等主链路稳定后，再补高频动作入口与快捷操作。"
        }
    }
}
