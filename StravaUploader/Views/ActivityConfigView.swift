import SwiftUI

struct ActivityConfigView: View {
    @Binding var activityType: ActivityType
    @Binding var activityName: String
    @Binding var activityDescription: String
    @Binding var isPrivate: Bool

    @FocusState private var focusedField: Field?

    private enum Field {
        case activityName
        case activityDescription
    }

    private let stravaOrange = Color(red: 252/255, green: 76/255, blue: 2/255)
    private let cardBackground = Color.white.opacity(0.1)

    var body: some View {
        VStack(spacing: 16) {
            // Activity Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("活动类型")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.6))

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
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .padding()
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            // Activity Name
            VStack(alignment: .leading, spacing: 8) {
                Text("活动名称 (可选)")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.6))

                TextField("例如: 晨骑", text: $activityName)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .focused($focusedField, equals: .activityName)
                    .padding()
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 12))
            }

            // Activity Description
            VStack(alignment: .leading, spacing: 8) {
                Text("活动描述 (可选)")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.6))

                TextField("添加备注...", text: $activityDescription, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .activityDescription)
                    .padding()
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 12))
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
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}