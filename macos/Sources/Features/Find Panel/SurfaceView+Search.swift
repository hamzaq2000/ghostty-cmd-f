import Foundation
import GhosttyKit

extension Ghostty.SurfaceView {
    /// Stores information about current search results.
    private class SearchState {
        var query: String
        var caseSensitive: Bool
        var handle: OpaquePointer
        var count: Int
        var currentIndex: Int = 0

        init(query: String, caseSensitive: Bool, handle: OpaquePointer, count: Int) {
            self.query = query
            self.caseSensitive = caseSensitive
            self.handle = handle
            self.count = count
        }

        deinit {
            ghostty_surface_search_free(handle)
        }
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

        let searchQuery = query

        // Perform search on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Perform the search (this holds the lock internally)
            guard let handle = searchQuery.withCString({ cString in
                ghostty_surface_search_create(surface, cString)
            }) else {
                DispatchQueue.main.async {
                    self.searchState = nil
                    completion(0)
                }
                return
            }

            // Get the count
            let count = Int(ghostty_surface_search_count(handle))

            guard count > 0 else {
                ghostty_surface_search_free(handle)
                DispatchQueue.main.async {
                    self.searchState = nil
                    completion(0)
                }
                return
            }

            // Create new search state
            let state = SearchState(query: searchQuery, caseSensitive: caseSensitive, handle: handle, count: count)

            // Update UI on main thread
            DispatchQueue.main.async {
                self.searchState = state
                completion(count)

                // Highlight the first match
                self.highlightMatch(at: 0)
            }
        }
    }

    /// Highlight a specific match by index.
    /// - Parameter index: The index of the match to highlight
    func highlightMatch(at index: Int) {
        guard let state = searchState,
              index >= 0,
              index < state.count,
              let surface = self.surface else {
            return
        }

        // Update the current index
        state.currentIndex = index

        // Highlight this match
        ghostty_surface_search_highlight(surface, state.handle, index)

        // Trigger a refresh to show the highlight
        ghostty_surface_refresh(surface)
    }

    /// Clear all search highlights.
    func clearSearchHighlights() {
        if let surface = self.surface {
            ghostty_surface_search_clear(surface)
        }
        searchState = nil
    }
}
