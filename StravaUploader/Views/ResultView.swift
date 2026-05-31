import SwiftUI

struct ResultView: View {
    let result: UploadResult
    let onRetry: () -> Void
    let onContinue: () -> Void

    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        VStack(spacing: 20) {
            switch result {
            case .success(let activityId, let activityUrl):
                SuccessView(activityId: activityId, activityUrl: activityUrl, onContinue: onContinue)

            case .duplicate(let activityId, let activityUrl):
                DuplicateView(activityId: activityId, activityUrl: activityUrl, onContinue: onContinue)

            case .failure(let error):
                FailureView(error: error, onRetry: onRetry)
            }
        }
        .padding()
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct SuccessView: View {
    let activityId: Int
    let activityUrl: String
    let onContinue: () -> Void

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)
    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("上传成功!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("活动已发布到 Strava")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.6))

            Button {
                if let url = URL(string: activityUrl) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("在 Strava 查看")
                }
                .font(.subheadline)
                .foregroundStyle(stravaOrange)
            }

            Button {
                onContinue()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("继续上传")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(stravaOrange, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }
}

struct DuplicateView: View {
    let activityId: Int
    let activityUrl: String
    let onContinue: () -> Void

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("文件已上传")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("检测到此文件已在 Strava 中存在")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: activityUrl) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("查看已有活动")
                }
                .font(.subheadline)
                .foregroundStyle(stravaOrange)
            }

            Button {
                onContinue()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("继续上传")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(stravaOrange, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }
}

struct FailureView: View {
    let error: String
    let onRetry: () -> Void

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("上传失败")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                onRetry()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重新上传")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(stravaOrange, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }
}