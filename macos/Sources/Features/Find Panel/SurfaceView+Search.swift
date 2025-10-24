import Foundation
import GhosttyKit

extension Ghostty.SurfaceView {
    /// Stores information about current search results.
    private class SearchState {
        var query: String
        var caseSensitive: Bool
        var matches: [SearchMatch] = []
        var currentIndex: Int = 0

        init(query: String, caseSensitive: Bool) {
            self.query = query
            self.caseSensitive = caseSensitive
        }
    }

    /// Represents a single search match location.
    private struct SearchMatch {
        var selection: ghostty_selection_s
    }

    /// The key for storing search state in associated objects.
    private static var searchStateKey: UInt8 = 0

    /// Get or create the search state for this surface view.
    private var searchState: SearchState? {
        get {
            objc_getAssociatedObject(self, &Self.searchStateKey) as? SearchState
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.searchStateKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// Perform a search on the terminal buffer.
    /// - Parameters:
    ///   - query: The search string
    ///   - caseSensitive: Whether the search should be case-sensitive
    ///   - completion: Called with the number of matches found
    func performSearch(query: String, caseSensitive: Bool, completion: @escaping (Int) -> Void) {
        guard !query.isEmpty, let surface = self.surface else {
            searchState = nil
            completion(0)
            return
        }

        // Clear any existing search
        clearSearchHighlights()

        // NOTE: The Zig search API is currently case-sensitive only
        let searchQuery = query

        // Perform search on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Create results structure
            var results = ghostty_search_results_s()

            // Perform the search (this holds the lock internally)
            let success = searchQuery.withCString { cString in
                ghostty_surface_search_create(surface, cString, &results)
            }

            guard success, results.count > 0 else {
                DispatchQueue.main.async {
                    self.searchState = nil
                    completion(0)
                }
                return
            }

            // Create new search state
            let state = SearchState(query: searchQuery, caseSensitive: caseSensitive)

            // Convert the C array to Swift array
            let selectionsBuffer = UnsafeBufferPointer(start: results.selections, count: results.count)
            state.matches = selectionsBuffer.map { SearchMatch(selection: $0) }

            // Free the C results
            ghostty_surface_search_free(&results)

            // Update UI on main thread
            DispatchQueue.main.async {
                self.searchState = state
                completion(state.matches.count)

                // If we have matches, highlight the first one
                if !state.matches.isEmpty {
                    self.highlightMatch(at: 0)
                }
            }
        }
    }

    /// Highlight a specific match by index.
    /// - Parameter index: The index of the match to highlight
    func highlightMatch(at index: Int) {
        guard let state = searchState,
              index >= 0,
              index < state.matches.count,
              let surface = self.surface else {
            return
        }

        // Update the current index
        state.currentIndex = index

        // TODO: Visual highlighting not yet implemented
        // Need to implement selection highlighting through C API
    }

    /// Clear all search highlights.
    func clearSearchHighlights() {
        searchState = nil
        // TODO: Clear visual highlighting when implemented
    }
}
