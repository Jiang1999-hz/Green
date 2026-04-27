import PhotosUI
import SwiftUI
import UIKit

struct GrowthRecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: GrowthRecordFormViewModel
    private let onSaveSuccess: ((GrowthRecordFormMode) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoLoadToken = UUID()
    @State private var isPresentingCamera = false
    @State private var isShowingCameraUnavailableAlert = false
    @State private var hasAttemptedSave = false

    init(
        viewModel: GrowthRecordFormViewModel,
        onSaveSuccess: ((GrowthRecordFormMode) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                detailsSection
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
            guard let selectedPhotoItem else {
                return
            }

            let previewImage = await loadPreviewImage(from: selectedPhotoItem)
            await viewModel.handleSelectedPhoto(
                assetIdentifier: selectedPhotoItem.itemIdentifier,
                previewImage: previewImage
            )
        }
        .sheet(isPresented: $isPresentingCamera) {
            CameraCaptureView(
                onCapture: { image in
                    Task {
                        await viewModel.saveCapturedPhoto(image)
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
            Text("请在真机上使用拍照功能，或改为从系统相册选择成长照片。")
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

    private var photoSection: some View {
        Section("成长照片") {
            HStack {
                Spacer()
                photoPreview
                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))

            if let photoValidationMessage = viewModel.photoValidationMessage, hasAttemptedSave {
                Text(photoValidationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.isProcessingPhoto {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在处理成长照片")
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

            if viewModel.draft.photoAssetIdentifier != nil {
                Button(role: .destructive) {
                    viewModel.removePhoto()
                } label: {
                    Label("移除成长照片", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let photoPreviewImage = viewModel.photoPreviewImage {
            Image(uiImage: photoPreviewImage)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            PhotoAssetImageView(
                assetIdentifier: viewModel.draft.photoAssetIdentifier,
                size: CGSize(width: 180, height: 180),
                cornerRadius: 28,
                placeholderSystemImage: "camera.macro"
            )
        }
    }

    private var detailsSection: some View {
        Section("记录信息") {
            DatePicker("记录时间", selection: $viewModel.draft.recordedAt)

            TextEditor(text: $viewModel.draft.note)
                .frame(minHeight: 120)

            Text("先记录照片、时间和观察备注。高度、健康识别和动画导出留给后续迭代接入。")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
