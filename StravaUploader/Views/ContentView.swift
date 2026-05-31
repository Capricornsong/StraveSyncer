import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UploadViewModel()

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                mainContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                HeaderView(stravaOrange: stravaOrange)
                    .padding(.top, 20)

                // Login / User Info Section
                if viewModel.isLoggedIn {
                    if let athlete = viewModel.athlete {
                        AthleteWelcomeCard(athlete: athlete, stravaOrange: stravaOrange)
                    } else {
                        LoginLoadingCard(stravaOrange: stravaOrange)
                    }
                } else {
                    LoginCard(
                        isLoading: viewModel.isLoggingIn,
                        error: viewModel.loginError,
                        stravaOrange: stravaOrange,
                        onLogin: {
                            viewModel.login()
                        }
                    )
                }

                FileSelectionView(
                    fileName: $viewModel.selectedFileName,
                    hasFile: Binding(
                        get: { viewModel.hasSelectedFile },
                        set: { _ in }
                    ),
                    onFileSelected: viewModel.handleFileSelection,
                    fileInfo: viewModel.fitFileInfo
                )

                if viewModel.hasSelectedFile {
                    if viewModel.isUploading {
                        UploadingView(stravaOrange: stravaOrange, status: viewModel.uploadStatus)
                            .transition(.opacity.combined(with: .scale))
                    } else if let result = viewModel.uploadResult {
                        ResultView(
                            result: result,
                            onRetry: {
                                Task {
                                    await viewModel.upload()
                                }
                            },
                            onContinue: {
                                viewModel.reset()
                            }
                        )
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        ActivityConfigView(
                            activityType: $viewModel.selectedActivityType,
                            activityName: $viewModel.activityName,
                            activityDescription: $viewModel.activityDescription,
                            isPrivate: $viewModel.isPrivate
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                        UploadButton(
                            isEnabled: viewModel.canUpload,
                            stravaOrange: stravaOrange,
                            onTap: {
                                Task {
                                    await viewModel.upload()
                                }
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isUploading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.uploadResult != nil)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if viewModel.isLoggedIn, viewModel.athlete != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.logout()
                        } label: {
                            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

struct LoginCard: View {
    let isLoading: Bool
    let error: String?
    let stravaOrange: Color
    let onLogin: () -> Void

    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(stravaOrange)

            Text("登录 Strava")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("授权后将自动获取上传所需的权限")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                onLogin()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle")
                    }
                    Text(isLoading ? "登录中..." : "使用 Strava 账户登录")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(stravaOrange, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
        }
        .padding(24)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct LoginLoadingCard: View {
    let stravaOrange: Color

    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .tint(stravaOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text("检测到用户信息")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("正在自动登陆...")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AthleteWelcomeCard: View {
    let athlete: Athlete
    let stravaOrange: Color

    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        Button {
            if let url = URL(string: "https://www.strava.com/athletes/\(athlete.id)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: athlete.profilePictureUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.white.opacity(0.6))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("已登录")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(athlete.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let city = athlete.city, let country = athlete.country {
                        Text("\(city), \(country)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale))
    }
}

struct HeaderView: View {
    let stravaOrange: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(stravaOrange)

            Text("Strava FIT Syncer")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("将 FIT 文件上传到您的 Strava 账户")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            // Supported activities info
            VStack(spacing: 4) {
                Text("支持的活动类型")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))

                Text("骑行 · 跑步 · 游泳 · 徒步 · 滑雪 · 水上运动")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Text("FIT 文件通常用于 GPS 运动手表和码表记录活动")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }
}

struct UploadButton: View {
    let isEnabled: Bool
    let stravaOrange: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "icloud.and.arrow.up")
                Text("上传到 Strava")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isEnabled ? stravaOrange : stravaOrange.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .disabled(!isEnabled)
    }
}

struct UploadingView: View {
    let stravaOrange: Color
    let status: String
    @State private var rotation: Double = 0

    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(stravaOrange.opacity(0.3), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(stravaOrange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(rotation))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(status.isEmpty ? "正在上传..." : status)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(status.isEmpty ? "请稍候" : "处理中...")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}