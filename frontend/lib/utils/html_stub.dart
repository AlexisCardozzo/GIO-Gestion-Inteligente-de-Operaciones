// Stub file for dart:html on non-web platforms

// This class provides stub implementations for html.window.open
// that will be used on non-web platforms
class Window {
  void open(String url, String target) {
    // No-op implementation for non-web platforms
    print('Cannot open URL on non-web platform: $url');
  }
}

// Expose a window object that mimics the one from dart:html
final Window window = Window();
