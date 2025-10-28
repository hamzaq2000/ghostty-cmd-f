# Ghostty with ⌘+F
A fork of [Ghostty](https://github.com/ghostty-org/ghostty) with scrollback search implemented for macOS. Use through `⌘+F`.

https://github.com/user-attachments/assets/7d393bc0-17ff-4b35-93c2-c3fce4a49e45

## macOS Build Instructions
Have Zig 0.15.2 installed
```
brew install zigup
zigup 0.15.2
```
Then build Ghostty
```
~/.local/share/zigup/0.15.2/files/zig build --release=fast
```
The built `.app` bundle will be found at
```
./zig-out/Ghostty.app
```

## Disclaimer
This was entirely vibecoded using Claude Code (Sonnet 4.5). There is a concurrency issue present that could cause a crash. Here's what Claude says:
```
The search operation in ghostty_surface_search reads from the PageList without holding a mutex, while the terminal thread could be modifying it simultaneously. Only the highlight operation (ghostty_surface_search_highlight) properly acquires the renderer mutex.

A crash could occur if the terminal deallocates or modifies a page (due to resize/reflow/scrollback) while the search thread is actively reading from it, causing a use-after-free or segfault.
I.e. don't search while there's any terminal activity going on.
```
