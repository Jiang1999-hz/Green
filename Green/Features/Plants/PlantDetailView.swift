import SwiftUI

struct PlantDetailView: View {
    private let container: AppContainer

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: PlantDetailViewModel
    @State private var isPresentingEdit = false
    @State private var isConfirmingDelete = false

    init(container: AppContainer, viewModel: PlantDetailViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let plant = viewModel.state.plant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection(for: plant)
                        overviewSection(for: plant)
                        notesSection(for: plant)
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
                    Button("编辑") {
                        isPresentingEdit = true
                    }
                }
            }
        }
        .task {
            viewModel.load()
        }
        .sheet(isPresented: $isPresentingEdit, onDismiss: {
            viewModel.load()
        }) {
            if let plant = viewModel.state.plant {
                PlantFormView(viewModel: container.makeEditPlantViewModel(plant: plant))
            }
        }
        .confirmationDialog(
            "删除这株植物后，对应成长记录也会一起移除。",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("删除植物", role: .destructive) {
                if viewModel.deletePlant() {
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

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil && viewModel.state.plant != nil },
            set: { newValue in
                if !newValue {
                    viewModel.load()
                }
            }
        )
    }
}
