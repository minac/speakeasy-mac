import SwiftUI

/// A text view that highlights the currently spoken word
struct HighlightedTextView: View {
    let text: String
    let highlightRange: NSRange?
    var highlightColor: Color = .accentColor

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(attributedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                    .textSelection(.enabled)
                    .id("textContent")
            }
            .onChange(of: highlightRange) { _, newRange in
                // Auto-scroll to keep highlighted word visible
                if newRange != nil {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo("textContent", anchor: .center)
                    }
                }
            }
        }
    }

    private var attributedText: AttributedString {
        var attributed = AttributedString(text)

        guard let range = highlightRange,
              range.location != NSNotFound,
              range.location + range.length <= text.utf16.count else {
            return attributed
        }

        // Convert NSRange to String.Index range
        let utf16 = text.utf16
        guard let start = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
              let end = utf16.index(start, offsetBy: range.length, limitedBy: utf16.endIndex),
              let swiftStart = start.samePosition(in: text),
              let swiftEnd = end.samePosition(in: text) else {
            return attributed
        }

        let swiftRange = swiftStart..<swiftEnd

        // Convert to AttributedString indices
        guard let attrStart = AttributedString.Index(swiftRange.lowerBound, within: attributed),
              let attrEnd = AttributedString.Index(swiftRange.upperBound, within: attributed) else {
            return attributed
        }

        // Apply highlight styling
        attributed[attrStart..<attrEnd].backgroundColor = highlightColor
        attributed[attrStart..<attrEnd].foregroundColor = .white

        return attributed
    }
}

#Preview {
    VStack {
        HighlightedTextView(
            text: "This is a sample text to demonstrate word highlighting during speech playback.",
            highlightRange: NSRange(location: 10, length: 6)  // "sample"
        )
        .frame(height: 100)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)

        HighlightedTextView(
            text: "No highlighting when range is nil",
            highlightRange: nil
        )
        .frame(height: 60)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)
    }
    .padding()
    .frame(width: 400)
}
