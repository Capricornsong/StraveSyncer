import SwiftUI

struct ActivityConfigView: View {
    @Binding var activityType: ActivityType
    @Binding var activityName: String
    @Binding var activityDescription: String
    @Binding var isPrivate: Bool

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)

    var body: some View {
        VStack(spacing: 16) {
            // Activity Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("活动类型")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(ActivityType.allCases) { type in
                        Button {
                            activityType = type
                        } label: {
                            Text(type.displayName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: activityType.icon)
                            .foregroundStyle(stravaOrange)
                        Text(activityType.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            // Activity Name
            VStack(alignment: .leading, spacing: 8) {
                Text("活动名称 (可选)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("例如: 晨骑", text: $activityName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            // Activity Description
            VStack(alignment: .leading, spacing: 8) {
                Text("活动描述 (可选)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("添加备注...", text: $activityDescription, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            // Private Toggle
            Toggle(isOn: $isPrivate) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(stravaOrange)
                    Text("设为私密活动")
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}