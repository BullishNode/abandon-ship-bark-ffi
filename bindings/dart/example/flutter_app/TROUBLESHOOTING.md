# Troubleshooting

Common issues when building the example app:

---

## ❗ Error: `Failed to invoke "rustup [...]"` / `No such file or directory` (macOS)

**Error message:**

```
RustBuilder: Failed to invoke "rustup [show, active-toolchain]"
ProcessException: No such file or directory
```

**Explanation:**
Xcode’s build environment does not inherit your shell PATH, so it cannot find `rustup` inside `~/.cargo/bin`.

**Fix:**

```bash
# Install rustup if it is missing:
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Symlink rustup so Xcode can find it:
sudo ln -sf "$HOME/.cargo/bin/rustup" /usr/local/bin/rustup
```

**Verify:**

```bash
/usr/local/bin/rustup show active-toolchain
```

---

## ❗ Error: `failed to run custom build command for bark-server-rpc` (macOS)

**Error message (example):**

```
failed to run custom build command for `bark-server-rpc`
Could not find protoc
```

**Explanation:**
The `bark-server-rpc` crate uses protobuf code generation and needs `protoc`.
Xcode cannot find Homebrew binaries unless explicitly symlinked.

**Fix:**

```bash
# Install protoc:
brew install protobuf

# Symlink protoc so Xcode can find it:
sudo ln -sf "$(command -v protoc)" /usr/local/bin/protoc
```

**Verify:**

```bash
/usr/local/bin/protoc --version
```

---

## 🧪 After applying fixes

Run:

```bash
flutter clean
flutter run
```
