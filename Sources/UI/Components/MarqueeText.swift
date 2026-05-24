import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    var color: Color = .primary
    
    @State private var animate = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(1)
                .offset(x: animate ? -100 : 0)
        }
        .disabled(true) // Prevent manual scrolling
        .mask(
            HStack(spacing: 0) {
                LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 8)
                Color.black
                LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 8)
            }
        )
    }
}
