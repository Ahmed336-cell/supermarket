import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "Supermarket"
    let width: CGFloat = 1280
    let height: CGFloat = 820
    if let screen = self.screen ?? NSScreen.main {
      let visible = screen.visibleFrame
      let frame = NSRect(
        x: visible.midX - width / 2,
        y: visible.midY - height / 2,
        width: width,
        height: height
      )
      self.setFrame(frame, display: true)
    }
    self.minSize = NSSize(width: 1100, height: 700)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
