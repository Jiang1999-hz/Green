import PhotosUI
import SwiftUI
import UIKit

struct PlantFormView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: PlantFormViewModel
    private let onSaveSuccess: ((PlantFormMode) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoLoadToken = UUID()
    @State private var isPresentingCamera = false
    @State private var isShowingCameraUnavailableAlert = false
    @State private var hasAttemptedSave = false

    init(
        viewModel: PlantFormViewModel,
        onSaveSuccess: ((PlantFormMode) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                coverPhotoSection
                profileSection
                notesSection
            }
            .navigationTitle(viewModel.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.mode.saveButtonTitle) {
                        if viewModel.save() {
                            onSaveSuccess?(viewModel.mode)
                            dismiss()
                        } else {
                            hasAttemptedSave = true
                        }
                    }
                    .disabled(viewModel.isBusy)
                }
            }
        }
        .task(id: selectedPhotoLoadToken) {
            guard let selectedPhotoItem = selectedPhotoItem else {
                return
            }

            let previewImage = await loadPreviewImage(from: selectedPhotoItem)
            await viewModel.handleSelectedCoverPhoto(
                assetIdentifier: selectedPhotoItem.itemIdentifier,
                previewImage: previewImage
            )
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraCaptureView(
                onCapture: { image in
                    Task {
                        await viewModel.saveCapturedCoverPhoto(image)
                        isPresentingCamera = false
                    }
                },
                onCancel: {
                    isPresentingCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .alert(
            "当前设备无法使用相机",
            isPresented: $isShowingCameraUnavailableAlert
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("请在真机上使用拍照功能，或改为从系统相册选择封面照片。")
        }
        .alert(
            "保存失败",
            isPresented: errorAlertBinding
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "请稍后重试。")
        }
    }

    private var coverPhotoSection: some View {
        Section("封面照片") {
            HStack {
                Spacer()

                coverPhotoPreview

                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))

            if viewModel.isProcessingCoverPhoto {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在处理封面照片")
                        .font(.subheadline)
                }
            }

            PhotosPicker(selection: selectedPhotoSelection, matching: .images) {
                Label("从相册选择", systemImage: "photo.on.rectangle")
            }

            Button {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    isShowingCameraUnavailableAlert = true
                    return
                }

                isPresentingCamera = true
            } label: {
                Label("拍照", systemImage: "camera")
            }

            if viewModel.draft.coverPhotoAssetIdentifier != nil {
                Button(role: .destructive) {
                    viewModel.removeCoverPhoto()
                } label: {
                    Label("移除封面照片", systemImage: "trash")
                }
            }

            Text("可从系统相册选择，或直接在 App 内拍摄并保存到“植物成长”相册。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var coverPhotoPreview: some View {
        if let previewImage = viewModel.coverPhotoPreviewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            PhotoAssetImageView(
                assetIdentifier: viewModel.draft.coverPhotoAssetIdentifier,
                size: CGSize(width: 180, height: 180),
                cornerRadius: 28,
                placeholderSystemImage: "photo.artframe"
            )
        }
    }

    private var profileSection: some View {
        Section("植物档案") {
            TextField("植物名称", text: $viewModel.draft.name)

            if let nameValidationMessage = viewModel.nameValidationMessage, hasAttemptedSave {
                Text(nameValidationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            TextField("植物种类", text: $viewModel.draft.species)
            TextField("摆放位置", text: $viewModel.draft.location)
            DatePicker("种植日期", selection: $viewModel.draft.plantedDate, displayedComponents: .date)

            Stepper(value: $viewModel.draft.wateringIntervalDays, in: 1 ... 365) {
                HStack {
                    Text("浇水频率")
                    Spacer()
                    Text("每 \(viewModel.draft.wateringIntervalDays) 天")
                        .foregroundStyle(.secondary)
                }
            }

            Text("保存后会按当前浇水频率生成提醒日期；编辑时只有修改浇水频率才会重算。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var notesSection: some View {
        Section("备注") {
            TextEditor(text: $viewModel.draft.notes)
                .frame(minHeight: 120)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var selectedPhotoSelection: Binding<PhotosPickerItem?> {
        Binding(
            get: { selectedPhotoItem },
            set: { newValue in
                selectedPhotoItem = newValue
                selectedPhotoLoadToken = UUID()
            }
        )
    }

    private func loadPreviewImage(from item: PhotosPickerItem) async -> UIImage? {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return nil
            }

            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
