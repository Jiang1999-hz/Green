import SwiftUI

struct PlantDashboardView: View {
    private let container: AppContainer

    @StateObject private var viewModel: PlantDashboardViewModel
    @State private var isPresentingCreatePlant = false

    init(container: AppContainer, viewModel: PlantDashboardViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    summarySection
                    plantListSection
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Green")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCreatePlant = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加植物")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreatePlant) {
            PlantFormView(viewModel: container.makeCreatePlantViewModel())
        }
        .task {
            await viewModel.observePlants()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("植物档案")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("为每株植物建立独立档案，集中管理封面照片、摆放位置、种植日期和浇水节奏。")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.88))

            Button {
                isPresentingCreatePlant = true
            } label: {
                Label("添加植物", systemImage: "leaf.fill.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
                    .foregroundStyle(AppTheme.dark)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.dark)
        )
    }

    private var summarySection: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 12) {
                summaryCard(
                    title: "植物总数",
                    value: viewModel.state.plantCountText,
                    detail: "首页卡片列表会展示所有植物档案。"
                )

                summaryCard(
                    title: "今日浇水",
                    value: viewModel.state.dueTodayText,
                    detail: "第 3 阶段会在这里接入通知和高亮提醒。"
                )
            }

            VStack(spacing: 12) {
                summaryCard(
                    title: "植物总数",
                    value: viewModel.state.plantCountText,
                    detail: "首页卡片列表会展示所有植物档案。"
                )

                summaryCard(
                    title: "今日浇水",
                    value: viewModel.state.dueTodayText,
                    detail: "第 3 阶段会在这里接入通知和高亮提醒。"
                )
            }
        }
    }

    private var plantListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("我的植物")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Spacer()

                Text(viewModel.state.plantCountText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.15), in: Capsule())
                    .foregroundStyle(AppTheme.primary)
            }

            if let errorMessage = viewModel.state.errorMessage {
                statusCard(
                    title: "植物档案暂时不可用",
                    detail: errorMessage
                )
            } else if viewModel.state.isLoading && viewModel.state.plants.isEmpty {
                loadingCard
            } else if viewModel.state.showsEmptyState {
                emptyStateCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.state.plants) { plant in
                        NavigationLink {
                            PlantDetailView(
                                container: container,
                                viewModel: container.makePlantDetailViewModel(plantID: plant.id)
                            )
                        } label: {
                            plantCard(plant)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func summaryCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.dark.opacity(0.72))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.dark)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(AppTheme.dark.opacity(0.68))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.9))
        )
    }

    private func plantCard(_ plant: PlantRecord) -> some View {
        HStack(spacing: 14) {
            PhotoAssetImageView(
                assetIdentifier: plant.coverPhotoAssetIdentifier,
                size: CGSize(width: 88, height: 88),
                cornerRadius: 20,
                placeholderSystemImage: "leaf.fill"
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.displayName)
                            .font(.headline)
                            .foregroundStyle(AppTheme.dark)

                        Text(plant.displaySpecies)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.dark.opacity(0.72))
                    }

                    Spacer(minLength: 8)

                    statusBadge(
                        text: plant.wateringStatusLabel,
                        highlight: plant.isWateringDueToday
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        metaBadge("种植 \(plant.daysSincePlanted) 天")
                        metaBadge(plant.displayLocation)
                    }

                    metaBadge(plant.nextWateringLabel)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.92))
        )
    }

    private func statusBadge(text: String, highlight: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(highlight ? .white : AppTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                highlight ? AppTheme.primary : AppTheme.primary.opacity(0.12),
                in: Capsule()
            )
    }

    private func metaBadge(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.1), in: Capsule())
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppTheme.primary)

            Text("正在加载植物档案")
                .font(.subheadline)
                .foregroundStyle(AppTheme.dark.opacity(0.72))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.86))
        )
    }

    private func statusCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.dark)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(AppTheme.dark.opacity(0.72))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.86))
        )
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("还没有植物档案")
                .font(.headline)
                .foregroundStyle(AppTheme.dark)

            Text(viewModel.state.emptySummaryText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.dark.opacity(0.72))

            Button {
                isPresentingCreatePlant = true
            } label: {
                Label("创建第一株植物", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.9))
        )
    }
}
