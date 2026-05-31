import SwiftUI
import UniformTypeIdentifiers

struct FileSelectionView: View {
    @Binding var fileName: String
    @Binding var hasFile: Bool
    let onFileSelected: (Result<[URL], Error>) -> Void
    let fileInfo: FitFileInfo?

    @State private var showFilePicker = false

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)
    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: hasFile ? "doc.fill" : "doc.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(stravaOrange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasFile ? "已选择文件" : "选择 FIT 文件")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if hasFile {
                        Text(fileName)
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                    } else {
                        Text("点击下方按钮选择 .fit 文件")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding()
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))

            if let info = fileInfo {
                FitFileInfoView(info: info, stravaOrange: stravaOrange)
            }

            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                    Text(hasFile ? "重新选择" : "选择文件")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(stravaOrange, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "fit") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            onFileSelected(result)
        }
    }
}

struct FitFileInfoView: View {
    let info: FitFileInfo
    let stravaOrange: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(stravaOrange.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(stravaOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("活动时间")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))

                    Text("\(info.displayDate) \(info.recordTime)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(stravaOrange.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "rectangle.portrait")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(stravaOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("设备信息")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))

                    Text("\(info.deviceName) \(info.deviceModel)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [stravaOrange.opacity(0.3), stravaOrange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}