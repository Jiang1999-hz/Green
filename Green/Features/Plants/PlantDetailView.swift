import SwiftUI

struct PlantDetailView: View {
    private let container: AppContainer
    private let onDeleteSuccess: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel: PlantDetailViewModel
    @State private var isPresentingEdit = false
    @State private var isPresentingCreateGrowthRecord = false
    @State private var isConfirmingDelete = false
    @State private var successMessage: String?
    @State private var successMessageTask: Task<Void, Never>?

    init(
        container: AppContainer,
        viewModel: PlantDetailViewModel,
        onDeleteSuccess: (() -> Void)? = nil
    ) {
        self.container = container
        self.onDeleteSuccess = onDeleteSuccess
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let plant = viewModel.state.plant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection(for: plant)
                        overviewSection(for: plant)
                        reminderSection(for: plant)
                        notesSection(for: plant)
                        growthTimelineSection
                        actionsSection
                    }
                    .padding(20)
                }
            } else if viewModel.state.isLoading {
                ProgressView("正在加载植物档案")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background.ignoresSafeArea())
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("植物档案不可用")
                        .font(.headline)
                        .foregroundStyle(AppTheme.dark)

                    Text(viewModel.state.errorMessage ?? "请返回首页后重试。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.dark.opacity(0.72))
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(viewModel.state.plant?.displayName ?? "植物详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.state.plant != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCreateGrowthRecord = true
                    } label: {
                        Image(systemName: "plus.viewfinder")
                    }
                    .accessibilityLabel("新增成长记录")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") {
                        isPresentingEdit = true
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isPresentingEdit, onDismiss: {
            Task {
                await viewModel.load()
            }
        }) {
            if let plant = viewModel.state.plant {
                PlantFormView(
                    viewModel: container.makeEditPlantViewModel(plant: plant),
                    onSaveSuccess: { _ in
                        showSuccessMessage("植物档案已更新。")
                    }
                )
            }
        }
        .sheet(isPresented: $isPresentingCreateGrowthRecord, onDismiss: {
            Task {
                await viewModel.load()
            }
        }) {
            if let plant = viewModel.state.plant {
                GrowthRecordFormView(
                    viewModel: container.makeCreateGrowthRecordViewModel(plantID: plant.id),
                    onSaveSuccess: { mode in
                        showSuccessMessage(mode.successMessage)
                    }
                )
            }
        }
        .confirmationDialog(
            "删除这株植物后，对应成长记录也会一起移除。",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("删除植物", role: .destructive) {
                if viewModel.deletePlant() {
                    onDeleteSuccess?()
                    dismiss()
                }
            }
        }
        .alert(
            "操作失败",
            isPresented: errorAlertBinding
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(viewModel.state.errorMessage ?? "请稍后重试。")
        }
        .safeAreaInset(edge: .top) {
            successBanner
        }
    }

    private func heroSection(for plant: PlantRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PhotoAssetImageView(
                assetIdentifier: plant.coverPhotoAssetIdentifier,
                size: CGSize(width: UIScreen.main.bounds.width - 40, height: 240),
                cornerRadius: 28,
                placeholderSystemImage: "leaf.fill"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(plant.displayName)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.dark)

                Text(plant.displaySpecies)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.dark.opacity(0.72))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        metricBadge(plant.wateringStatusLabel, filled: plant.isWateringDueToday)
                        metricBadge("种植 \(plant.daysSincePlanted) 天")
                    }

                    metricBadge(plant.displayLocation)
                }
            }
        }
    }

    private func overviewSection(for plant: PlantRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("档案信息")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            infoRow(title: "摆放位置", value: plant.displayLocation)
            infoRow(title: "种植日期", value: plant.plantedDateLabel)
            infoRow(title: "浇水频率", value: plant.wateringIntervalLabel)
            infoRow(title: "下次浇水", value: plant.nextWateringLabel)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.92))
        )
    }

    private func notesSection(for plant: PlantRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            Text(plant.notes?.isEmpty == false ? plant.notes ?? "" : "还没有补充养护备注。")
                .font(.body)
                .foregroundStyle(AppTheme.dark.opacity(0.74))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.92))
        )
    }

    private func reminderSection(for plant: PlantRecord) -> some View {
        let snapshot = viewModel.state.reminderSnapshot

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("浇水提醒")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Spacer()

                if viewModel.state.isRefreshingReminder {
                    ProgressView()
                        .tint(AppTheme.primary)
                }
            }

            infoRow(
                title: "提醒状态",
                value: snapshot?.statusLabel ?? "正在检查"
            )
            infoRow(
                title: "通知权限",
                value: snapshot?.permissionState.displayLabel ?? "正在检查"
            )
            infoRow(
                title: "上次浇水",
                value: plant.lastWateredLabel
            )
            infoRow(
                title: "预计触发",
                value: snapshot?.scheduledDateLabel ?? "未安排"
            )

            Text(snapshot?.detailLabel ?? "正在读取当前植物的提醒状态。")
                .font(.footnote)
                .foregroundStyle(AppTheme.dark.opacity(0.68))

            Button {
                Task {
                    let didMark = await viewModel.markPlantWateredNow()
                    if didMark {
                        showSuccessMessage("\(plant.displayName) 已标记为今天浇水。")
                    }
                }
            } label: {
                Label("今天已浇水", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(viewModel.state.isRefreshingReminder)

            reminderActionRow(for: plant, snapshot: snapshot)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.92))
        )
    }

    private var growthTimelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("成长时间线")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Spacer()

                if let plant = viewModel.state.plant, !viewModel.state.growthRecords.isEmpty {
                    NavigationLink {
                        GrowthRecordsOverviewView(
                            container: container,
                            viewModel: container.makeGrowthRecordsOverviewViewModel(plant: plant)
                        )
                    } label: {
                        Text("查看全部")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(AppTheme.primary)
                }

                Button {
                    isPresentingCreateGrowthRecord = true
                } label: {
                    Label("新增记录", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(AppTheme.primary)
            }

            if viewModel.state.growthRecords.isEmpty {
                Text("先记录一张成长照片，后续时间线、健康分析和动画都会围绕这些记录展开。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.dark.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.92))
                    )
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.state.recentGrowthRecords) { record in
                        growthRecordCard(record)
                    }
                }

                if let plant = viewModel.state.plant, viewModel.state.hasMoreGrowthRecords {
                    NavigationLink {
                        GrowthRecordsOverviewView(
                            container: container,
                            viewModel: container.makeGrowthRecordsOverviewViewModel(plant: plant)
                        )
                    } label: {
                        HStack(spacing: 10) {
                            stagePreviewBadge

                            VStack(alignment: .leading, spacing: 4) {
                                Text("查看全部成长记录")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.dark)

                                Text(viewModel.state.growthJourneyStage.progressLabel)
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.dark.opacity(0.64))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(AppTheme.dark.opacity(0.44))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppTheme.primary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("操作")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("删除植物档案", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.bottom, 20)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.dark)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.dark.opacity(0.74))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricBadge(_ text: String, filled: Bool = false) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? .white : AppTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                filled ? AppTheme.primary : AppTheme.primary.opacity(0.1),
                in: Capsule()
            )
    }

    private func growthRecordCard(_ record: GrowthRecordEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PhotoAssetImageView(
                assetIdentifier: record.photoAssetIdentifier,
                size: CGSize(width: 80, height: 80),
                cornerRadius: 18,
                placeholderSystemImage: "camera.macro"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(record.recordedDateLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Text(record.displayNote)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(AppTheme.dark.opacity(0.76))

                Text(record.recordedTimestampLabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.dark.opacity(0.54))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.92))
        )
    }

    @ViewBuilder
    private func reminderActionRow(
        for plant: PlantRecord,
        snapshot: WateringReminderSnapshot?
    ) -> some View {
        switch snapshot?.permissionState {
        case .denied:
            Button {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                openURL(settingsURL)
            } label: {
                Label("打开系统设置", systemImage: "gearshape.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.primary)

        case .authorized, .provisional, .ephemeral:
            Button {
                Task {
                    let didSchedule = await viewModel.enableOrRefreshReminder()
                    if didSchedule {
                        showSuccessMessage("已为\(plant.displayName)更新浇水提醒。")
                    }
                }
            } label: {
                Label("刷新提醒", systemImage: "bell.badge")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(viewModel.state.isRefreshingReminder)

        case .notDetermined, nil:
            Button {
                Task {
                    let didSchedule = await viewModel.enableOrRefreshReminder()
                    if didSchedule {
                        showSuccessMessage("浇水提醒已开启。")
                    }
                }
            } label: {
                Label("开启提醒", systemImage: "bell.badge.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(viewModel.state.isRefreshingReminder)
        }
    }

    private var stagePreviewBadge: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.14))
                .frame(width: 52, height: 52)

            Image(systemName: viewModel.state.growthJourneyStage.kind.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil && viewModel.state.plant != nil },
            set: { newValue in
                if !newValue {
                    Task {
                        await viewModel.load()
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var successBanner: some View {
        if let successMessage {
            Text(successMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func showSuccessMessage(_ message: String) {
        successMessageTask?.cancel()

        withAnimation(.spring(duration: 0.28)) {
            successMessage = message
        }

        successMessageTask = Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                withAnimation(.spring(duration: 0.28)) {
                    successMessage = nil
                }
            }
        }
    }
}
