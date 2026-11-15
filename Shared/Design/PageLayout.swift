import SwiftUI

/// A page's heading and description, with the storage badge on the right like the web pages.
struct PageHeader<Trailing: View>: View {
  var title: String
  var description: String?
  @ViewBuilder var trailing: Trailing

  var body: some View {
    HStack(alignment: .bottom, spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.foreground)
        if let description {
          Text(description).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).fixedSize(horizontal: false, vertical: true)
        }
      }
      Spacer(minLength: 0)
      trailing
    }
  }
}

extension PageHeader where Trailing == StorageBadge {
  init(title: String, description: String? = nil) {
    self.init(title: title, description: description) { StorageBadge() }
  }
}

/// The page's content column: centred with the web's max width and padding.
struct PageScroll<Content: View>: View {
  var maxWidth: CGFloat = 960
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) { content }
        .frame(maxWidth: maxWidth, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
    }
    .background(Palette.page)
  }
}
