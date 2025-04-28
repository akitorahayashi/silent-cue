import SCShared
import SwiftUI

struct CancelButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("キャンセル")
                .foregroundStyle(.primary)
                .font(.system(size: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
