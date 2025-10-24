import SwiftUI
import GhosttyKit

/// A find panel overlay that allows searching for text in the terminal.
struct FindPanelView: View {
    /// The surface that this find panel searches.
    let surfaceView: Ghostty.SurfaceView

    /// Set this to true to show the view, this will be set to false when dismissed.
    @Binding var isPresented: Bool

    /// The search query text.
    @State private var searchText: String = ""

    /// Current match index (0-based).
    @State private var currentMatchIndex: Int = 0

    /// Total number of matches found.
    @State private var totalMatches: Int = 0

    /// Focus state for the search field.
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Spacer()

            // Search text field
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                TextField("Find", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(width: 200)
                    .focused($searchFieldFocused)
                    .onSubmit {
                        findNext()
                    }
                    .onChange(of: searchText) { newValue in
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        totalMatches = 0
                        currentMatchIndex = 0
                        clearHighlights()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)

            // Match counter
            if totalMatches > 0 {
                Text("\(currentMatchIndex + 1) of \(totalMatches)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            } else if !searchText.isEmpty {
                Text("No results")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            // Previous button
            Button(action: findPrevious) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .disabled(totalMatches == 0)
            .help("Find Previous (Shift+Return)")

            // Next button
            Button(action: findNext) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .disabled(totalMatches == 0)
            .help("Find Next (Return)")

            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Close (Escape)")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(NSColor.controlBackgroundColor)
                .opacity(0.95)
        )
        .onAppear {
            // Focus the search field when the view appears
            DispatchQueue.main.async {
                searchFieldFocused = true
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                // Focus the search field when shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    searchFieldFocused = true
                }
            } else {
                // Clear search when dismissed
                searchText = ""
                totalMatches = 0
                currentMatchIndex = 0
                clearHighlights()

                // Return focus to terminal
                DispatchQueue.main.async {
                    surfaceView.window?.makeFirstResponder(surfaceView)
                }
            }
        }
    }

    /// Perform a search with the current search text.
    private func performSearch() {
        guard !searchText.isEmpty else {
            totalMatches = 0
            currentMatchIndex = 0
            clearHighlights()
            return
        }

        // Capture the search text to check if it's still current when results come back
        let capturedSearchText = searchText

        // Search is case-insensitive by default
        surfaceView.performSearch(query: searchText, caseSensitive: false) { matches in
            // If search text changed or was cleared, clear highlights and ignore results
            if self.searchText != capturedSearchText {
                self.clearHighlights()
                return
            }

            totalMatches = matches
            if matches > 0 {
                currentMatchIndex = 0
            } else {
                currentMatchIndex = 0
            }
        }
    }

    /// Find the next match.
    private func findNext() {
        guard totalMatches > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % totalMatches
        surfaceView.highlightMatch(at: currentMatchIndex)
    }

    /// Find the previous match.
    private func findPrevious() {
        guard totalMatches > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + totalMatches) % totalMatches
        surfaceView.highlightMatch(at: currentMatchIndex)
    }

    /// Clear all search highlights.
    private func clearHighlights() {
        surfaceView.clearSearchHighlights()
    }
}
