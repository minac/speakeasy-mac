import SwiftUI
import AppKit

/// A text view that highlights the currently spoken word and scrolls to follow it
struct HighlightedTextView: NSViewRepresentable {
    let text: String
    let highlightRange: NSRange?
    var highlightColor: Color = .accentColor

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text content
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributedString.length)

        // Base styling
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.textColor
        ], range: fullRange)

        // Apply highlight if we have a valid range
        if let range = highlightRange,
           range.location != NSNotFound,
           range.location + range.length <= text.utf16.count {
            let nsHighlightColor = NSColor(highlightColor)
            attributedString.addAttributes([
                .backgroundColor: nsHighlightColor,
                .foregroundColor: NSColor.white
            ], range: range)
        }

        // Only update text if changed to avoid scroll jumping
        if textView.attributedString() != attributedString {
            textView.textStorage?.setAttributedString(attributedString)
        } else if let range = highlightRange,
                  range.location != NSNotFound,
                  range.location + range.length <= text.utf16.count {
            // Text same but highlight changed - just update attributes
            textView.textStorage?.setAttributes([
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.textColor
            ], range: fullRange)
            textView.textStorage?.addAttributes([
                .backgroundColor: NSColor(highlightColor),
                .foregroundColor: NSColor.white
            ], range: range)
        }

        // Scroll to keep highlighted word visible
        if let range = highlightRange,
           range.location != NSNotFound,
           range.location + range.length <= text.utf16.count {
            // Use scrollRangeToVisible to smoothly scroll to the highlighted word
            textView.scrollRangeToVisible(range)
        }
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
