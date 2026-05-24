import SwiftUI

struct LyricRow: View {
    let line: LyricLine
    let isActive: Bool
    
    var body: some View {
        Text(line.text)
            .font(.system(size: isActive ? 16 : 14, weight: isActive ? .bold : .medium, design: .rounded))
            .foregroundColor(isActive ? .accentColor : .primary)
            .opacity(isActive ? 1.0 : 0.5)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isActive ? 
                Color.accentColor.opacity(0.12)
                    .cornerRadius(8) 
                : Color.clear.cornerRadius(0)
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}
