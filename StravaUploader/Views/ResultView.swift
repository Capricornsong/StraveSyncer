import SwiftUI

struct ResultView: View {
    let result: UploadResult
    let onRetry: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            switch result {
            case .success(let activityId, let activityUrl):
                SuccessView(activityId: activityId, activityUrl: activityUrl, onContinue: onContinue)

            case .failure(let error):
                FailureView(error: error, onRetry: onRetry)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct SuccessView: View {
    let activityId: Int
    let activityUrl: String
    let onContinue: () -> Void

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("上传成功!")
                .font(.title2)
                .fontWeight(.bold)

            if activityId > 0 {
                Text("活动 ID: \(activityId)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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