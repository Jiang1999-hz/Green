import AVKit
import SwiftUI

struct GrowthRecordsOverviewView: View {
    private let container: AppContainer

    @StateObject private var viewModel: GrowthRecordsOverviewViewModel
    @State private var editingRecord: GrowthRecordEntry?
    @State private var deletingRecord: GrowthRecordEntry?
    @State private var previewVideoURL: URL?
    @State private var successMessage: String?
    @State private var successMessageTask: Task<Void, Never>?

    init(container: AppContainer, viewModel: GrowthRecordsOverviewViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var growthStage: GrowthJourneyStage {
        GrowthJourneyStage(recordCount: viewModel.state.growthRecords.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                growthHeroCard
                historySection
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("全部成长记录")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.load()
        }
        .sheet(item: $editingRecord, onDismiss: {
            viewModel.load()
        }) { record in
            GrowthRecordFormView(
                viewModel: container.makeEditGrowthRecordViewModel(record: record),
                onSaveSuccess: { mode in
                    showSuccessMessage(mode.successMessage)
                }
            )
        }
        .sheet(isPresented: previewVideoSheetBinding) {
            if let previewVideoURL {
                GrowthAnimationPreviewView(videoURL: previewVideoURL)
            }
        }
        .confirmationDialog(
            "删除后，这条成长记录将无法恢复。",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("删除记录", role: .destructive) {
                guard let deletingRecord else {
                    return
                }

                if viewModel.deleteGrowthRecord(id: deletingRecord.id) {
                    showSuccessMessage("成长记录已删除。")
                }

                self.deletingRecord = nil
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

    private var growthHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.plant.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.dark)

                Text(growthStage.kind.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)

                Text(growthStage.supportLabel)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.dark.opacity(0.64))
            }

            themeSelector

            GrowthThemeHeroView(
                stage: growthStage,
                theme: viewModel.selectedTheme
            )

            animationExportSection

            stageProgressBar

            Text(growthStage.progressLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.dark.opacity(0.74))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            AppTheme.primary.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("成长风格")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            HStack(spacing: 10) {
                ForEach(GrowthTheme.builtInThemes) { theme in
                    Button {
                        viewModel.selectTheme(theme.kind)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.title)
                                .font(.caption.weight(.semibold))

                            Text(theme.subtitle)
                                .font(.caption2)
                                .lineLimit(2)
                        }
                        .foregroundStyle(viewModel.state.selectedThemeKind == theme.kind ? .white : AppTheme.dark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(viewModel.state.selectedThemeKind == theme.kind ? AppTheme.primary : .white.opacity(0.72))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("后续会在这里扩展更多成长主题，支持用户选择不同视觉风格。")
                .font(.caption)
                .foregroundStyle(AppTheme.dark.opacity(0.58))
        }
    }

    private var stageProgressBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.primary.opacity(0.14))
                        .frame(height: 10)

                    Capsule()
                        .fill(AppTheme.primary)
                        .frame(width: geometry.size.width * progressFraction, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                ForEach(GrowthJourneyStage.Kind.allCases, id: \.self) { kind in
                    Text(kind.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(kind.rawValue <= growthStage.currentStageIndex ? AppTheme.primary : AppTheme.dark.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var animationExportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("成长动画")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            Text("把当前成长照片串成一段本地延时动画，导出后可以直接分享。")
                .font(.caption)
                .foregroundStyle(AppTheme.dark.opacity(0.62))

            if viewModel.state.isExportingAnimation {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: viewModel.state.exportProgress, total: 1)
                        .tint(AppTheme.primary)

                    Text(viewModel.state.exportStatusMessage ?? "正在生成成长动画…")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.dark.opacity(0.72))
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        if await viewModel.exportGrowthAnimation() {
                            showSuccessMessage("成长动画已生成。")
                        }
                    }
                } label: {
                    Label(
                        viewModel.state.isExportingAnimation ? "正在生成" : "生成动画",
                        systemImage: viewModel.state.isExportingAnimation ? "hourglass" : "sparkles.tv"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .disabled(viewModel.state.isExportingAnimation || viewModel.state.growthRecords.isEmpty)

                if let exportedVideoURL = viewModel.state.exportedVideoURL {
                    Button {
                        previewVideoURL = exportedVideoURL
                    } label: {
                        Label("预览视频", systemImage: "play.rectangle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.primary)

                    ShareLink(item: exportedVideoURL) {
                        Label("分享视频", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.primary)
                }
            }
        }
    }

    private var progressFraction: CGFloat {
        let totalStages = max(CGFloat(GrowthJourneyStage.Kind.allCases.count - 1), 1)
        return CGFloat(growthStage.currentStageIndex) / totalStages
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("全部成长记录")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.dark)

            Text("长按记录卡片可编辑或删除。")
                .font(.caption)
                .foregroundStyle(AppTheme.dark.opacity(0.58))

            ForEach(viewModel.state.growthRecords) { record in
                historyRow(record)
            }
        }
    }

    private func historyRow(_ record: GrowthRecordEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PhotoAssetImageView(
                assetIdentifier: record.photoAssetIdentifier,
                size: CGSize(width: 72, height: 72),
                cornerRadius: 18,
                placeholderSystemImage: "camera.macro"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(record.recordedDateLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.dark)

                Text(record.displayNote)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(AppTheme.dark.opacity(0.72))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.92))
        )
        .contextMenu {
            Button("编辑记录") {
                editingRecord = record
            }

            Button("删除记录", role: .destructive) {
                deletingRecord = record
            }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { deletingRecord != nil },
            set: { newValue in
                if !newValue {
                    deletingRecord = nil
                }
            }
        )
    }

    private var previewVideoSheetBinding: Binding<Bool> {
        Binding(
            get: { previewVideoURL != nil },
            set: { newValue in
                if !newValue {
                    previewVideoURL = nil
                }
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.load()
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

private struct GrowthAnimationPreviewView: View {
    let videoURL: URL

    @State private var player: AVPlayer

    init(videoURL: URL) {
        self.videoURL = videoURL
        _player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .background(Color.black.ignoresSafeArea())
                .navigationTitle("成长动画预览")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
        }
    }
}
