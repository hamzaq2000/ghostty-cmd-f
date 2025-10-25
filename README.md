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