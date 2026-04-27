import SwiftUI

private enum DashboardQuickActionPicker {
    case growthRecord
    case watering
}

struct PlantDashboardView: View {
    private let container: AppContainer

    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel: PlantDashboardViewModel
    @State private var isPresentingCreatePlant = false
    @State private var selectedGrowthRecordPlant: PlantRecord?
    @State private var isShowingNotificationMenu = false
    @State private var isShowingQuickActions = false
    @State private var activeQuickActionPicker: DashboardQuickActionPicker?
    @State private var successMessage: String?
    @State private var successMessageTask: Task<Void, Never>?

    init(container: AppContainer, viewModel: PlantDashboardViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection
                        summarySection
                        plantListSection
                    }
                    .padding(20)
                    .padding(.bottom, 110)
                }
                .background(AppTheme.background.ignoresSafeArea())
                .allowsHitTesting(!isShowingQuickActions)

                if isShowingQuickActions {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            closeQuickActions()
                        }
                }

                quickActionFab
            }
            .navigationTitle("Green")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleNotificationButtonTap()
                    } label: {
                        if viewModel.state.isUpdatingNotificationPermission {
                            ProgressView()
                                .tint(notificationIndicatorColor)
                        } else {
                            Image(systemName: viewModel.state.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                                .foregroundStyle(notificationIndicatorColor)
                        }
                    }
                    .accessibilityLabel(viewModel.state.notificationsEnabled ? "通知已开启" : "通知未开启")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreatePlant) {
            PlantFormView(
                viewModel: container.makeCreatePlantViewModel(),
                onSaveSuccess: { _ in
                    showSuccessMessage("植物档案已创建。")
                }
            )
        }
        .sheet(item: $selectedGrowthRecordPlant, onDismiss: {
            closeQuickActions()
        }) { plant in
            GrowthRecordFormView(
                viewModel: container.makeCreateGrowthRecordViewModel(plantID: plant.id),
                onSaveSuccess: { mode in
                    showSuccessMessage(mode.successMessage)
                }
            )
        }
        .task {
            await viewModel.observePlants()
            await viewModel.refreshNotificationPermissionState()
        }
        .confirmationDialog(
            "通知状态",
            isPresented: $isShowingNotificationMenu,
            titleVisibility: .visible
        ) {
            Button("通知已开启") {}
            Button("前往系统设置") {
                openNotificationSettings()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("Green 当前可以发送浇水提醒，如需关闭，请前往系统设置。")
        }
        .confirmationDialog(
            quickActionPickerTitle,
            isPresented: quickActionPickerBinding,
            titleVisibility: .visible
        ) {
            switch activeQuickActionPicker {
            case .growthRecord:
                ForEach(viewModel.state.growthQuickActionCandidates) { plant in
                    Button(plant.displayName) {
                        selectedGrowthRecordPlant = plant
                    }
                }
            case .watering:
                ForEach(viewModel.state.wateringQuickActionCandidates) { plant in
                    Button(plant.displayName) {
                        markPlantWatered(plant)
                    }
                }
            case nil:
                EmptyView()
            }

            Button("取消", role: .cancel) {
                closeQuickActions()
            }
        } message: {
            Text(quickActionPickerMessage)
        }
        .safeAreaInset(edge: .top) {
            successBanner
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

    private var quickActionFab: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isShowingQuickActions {
                quickActionButton(
                    title: "今天已浇水",
                    systemImage: "drop.fill",
                    accent: Color.green,
                    detail: viewModel.state.wateringQuickActionDetailText,
                    disabled: viewModel.state.wateringQuickActionCandidates.isEmpty
                ) {
                    triggerWateringQuickAction()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale(scale: 0.94).combined(with: .opacity)
                    )
                )

                quickActionButton(
                    title: "记录成长",
                    systemImage: "camera.macro",
                    accent: AppTheme.primary,
                    detail: viewModel.state.growthQuickActionDetailText,
                    disabled: viewModel.state.growthQuickActionCandidates.isEmpty
                ) {
                    triggerGrowthQuickAction()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale(scale: 0.94).combined(with: .opacity)
                    )
                )

                quickActionButton(
                    title: "添加植物",
                    systemImage: "leaf.fill.badge.plus",
                    accent: AppTheme.dark
                ) {
                    isPresentingCreatePlant = true
                    closeQuickActions()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale(scale: 0.94).combined(with: .opacity)
                    )
                )
            }

            Button {
                toggleQuickActions()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isShowingQuickActions ? "xmark" : "bolt.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(AppTheme.primary, in: Circle())
                        .rotationEffect(.degrees(isShowingQuickActions ? 45 : 0))
                        .scaleEffect(isShowingQuickActions ? 0.94 : 1)
                        .shadow(color: AppTheme.primary.opacity(0.26), radius: 16, y: 10)

                    if !isShowingQuickActions, viewModel.state.dueWateringQuickActionCount > 0 {
                        Text("\(viewModel.state.dueWateringQuickActionCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.green, in: Capsule())
                            .offset(x: 4, y: -4)
                        }
                }
            }
            .accessibilityLabel(isShowingQuickActions ? "收起快捷入口" : "展开快捷入口")
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isShowingQuickActions)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
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
                    detail: viewModel.state.wateringProgressDetailText
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
                    detail: viewModel.state.wateringProgressDetailText
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
                                viewModel: container.makePlantDetailViewModel(plantID: plant.id),
                                onDeleteSuccess: {
                                    showSuccessMessage("植物档案已删除。")
                                }
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
                        highlight: plant.isWateringDueToday,
                        completed: plant.isWateredToday
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        metaBadge("种植 \(plant.daysSincePlanted) 天")
                        metaBadge(plant.displayLocation)
                    }

                    HStack(spacing: 8) {
                        metaBadge(plant.nextWateringLabel)
                        metaBadge("上次 \(plant.lastWateredLabel)")
                    }
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

    private func statusBadge(text: String, highlight: Bool, completed: Bool = false) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(highlight || completed ? .white : AppTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                completed ? Color.green : (highlight ? AppTheme.primary : AppTheme.primary.opacity(0.12)),
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

    private func quickActionButton(
        title: String,
        systemImage: String,
        accent: Color,
        detail: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.dark)

                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.dark.opacity(0.56))
                    }
                }

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(accent, in: Circle())
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .background(.white.opacity(disabled ? 0.68 : 0.96), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.55))
            }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.58 : 1)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var notificationIndicatorColor: Color {
        viewModel.state.notificationsEnabled ? .green : .red
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

    private var quickActionPickerBinding: Binding<Bool> {
        Binding(
            get: { activeQuickActionPicker != nil },
            set: { newValue in
                if !newValue {
                    activeQuickActionPicker = nil
                }
            }
        )
    }

    private var quickActionPickerTitle: String {
        switch activeQuickActionPicker {
        case .growthRecord:
            return "选择要记录成长的植物"
        case .watering:
            return "选择今天已浇水的植物"
        case nil:
            return ""
        }
    }

    private var quickActionPickerMessage: String {
        switch activeQuickActionPicker {
        case .growthRecord:
            return "先选一株植物，再直接进入成长记录表单。"
        case .watering:
            return "优先显示今天待处理的植物，选中后会立即刷新浇水状态和提醒。"
        case nil:
            return ""
        }
    }

    private func handleNotificationButtonTap() {
        switch viewModel.state.reminderPermissionState {
        case .authorized, .provisional, .ephemeral:
            isShowingNotificationMenu = true
        case .notDetermined:
            Task {
                await viewModel.requestNotificationPermissionIfNeeded()
            }
        case .denied:
            openNotificationSettings()
        }
    }

    private func openNotificationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }

    private func triggerGrowthQuickAction() {
        let candidates = viewModel.state.growthQuickActionCandidates
        guard !candidates.isEmpty else {
            return
        }

        if candidates.count == 1 {
            selectedGrowthRecordPlant = candidates[0]
            return
        }

        activeQuickActionPicker = .growthRecord
    }

    private func triggerWateringQuickAction() {
        let candidates = viewModel.state.wateringQuickActionCandidates
        guard !candidates.isEmpty else {
            return
        }

        if candidates.count == 1 {
            markPlantWatered(candidates[0])
            return
        }

        activeQuickActionPicker = .watering
    }

    private func markPlantWatered(_ plant: PlantRecord) {
        Task {
            if let updatedPlant = await viewModel.markPlantWatered(plantID: plant.id) {
                showSuccessMessage("\(updatedPlant.displayName) 已标记为今天浇水。")
            }
            closeQuickActions()
        }
    }

    private func toggleQuickActions() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            isShowingQuickActions.toggle()
        }
    }

    private func closeQuickActions() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isShowingQuickActions = false
        }
        activeQuickActionPicker = nil
    }
}
