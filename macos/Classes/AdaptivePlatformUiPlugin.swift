import Cocoa
import FlutterMacOS

public class AdaptivePlatformUiPlugin: NSObject, FlutterPlugin {
  private weak var flutterView: NSView?
  private var pickedTag: Int?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "adaptive_platform_ui/macos",
      binaryMessenger: registrar.messenger
    )
    let instance = AdaptivePlatformUiPlugin()
    instance.flutterView = registrar.view
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showMenu":
      showMenu(call.arguments, result: result)
    case "showAlert":
      showAlert(call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @objc private func pickMenuItem(_ sender: NSMenuItem) {
    pickedTag = sender.tag
  }

  private func resolvedView() -> NSView? {
    if let view = flutterView, view.bounds.width > 1, view.bounds.height > 1 {
      return view
    }
    return NSApp.keyWindow?.contentView
  }

  private func showMenu(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let args = arguments as? [String: Any],
      let x = args["x"] as? Double,
      let y = args["y"] as? Double,
      let height = args["height"] as? Double,
      let items = args["items"] as? [[String: Any]],
      let view = resolvedView()
    else {
      result(nil)
      return
    }

    let flutterViewWidth = (args["viewWidth"] as? Double).flatMap { $0 > 1 ? $0 : nil } ?? view.bounds.width
    let flutterViewHeight = (args["viewHeight"] as? Double).flatMap { $0 > 1 ? $0 : nil } ?? view.bounds.height
    let scaleX = view.bounds.width / flutterViewWidth
    let scaleY = view.bounds.height / flutterViewHeight

    let menu = NSMenu()
    menu.autoenablesItems = false
    pickedTag = nil

    for item in items {
      if (item["type"] as? String) == "divider" {
        menu.addItem(.separator())
        continue
      }

      let label = item["label"] as? String ?? ""
      let index = item["index"] as? Int ?? 0
      let menuItem = NSMenuItem(title: label, action: #selector(pickMenuItem(_:)), keyEquivalent: "")
      menuItem.target = self
      menuItem.tag = index
      menuItem.isEnabled = item["enabled"] as? Bool ?? true
      menuItem.state = (item["selected"] as? Bool ?? false) ? .on : .off
      if let symbol = item["symbol"] as? String, !symbol.isEmpty {
        menuItem.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
      }
      if item["destructive"] as? Bool ?? false {
        menuItem.attributedTitle = NSAttributedString(
          string: label,
          attributes: [.foregroundColor: NSColor.systemRed]
        )
      }
      menu.addItem(menuItem)
    }

    // Flutter reports top-left logical points. FlutterView is often flipped
    // (top-left origin). A second flip then parks the menu on the floor.
    let flutterY = (y + height) * scaleY
    let pointInView = NSPoint(
      x: x * scaleX,
      y: view.isFlipped ? flutterY : view.bounds.height - flutterY
    )

    if let window = view.window {
      let inWindow = view.convert(pointInView, to: nil)
      let inScreen = window.convertToScreen(NSRect(origin: inWindow, size: .zero)).origin
      menu.popUp(positioning: nil, at: inScreen, in: nil)
    } else {
      menu.popUp(positioning: nil, at: pointInView, in: view)
    }
    result(pickedTag)
  }

  private func showAlert(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let args = arguments as? [String: Any],
      let title = args["title"] as? String,
      let actions = args["actions"] as? [[String: Any]]
    else {
      result(nil)
      return
    }

    let alert = NSAlert()
    alert.messageText = title
    if let message = args["message"] as? String, !message.isEmpty {
      alert.informativeText = message
    }

    if actions.isEmpty {
      alert.addButton(withTitle: "OK")
    } else {
      for action in actions {
        let button = alert.addButton(withTitle: action["title"] as? String ?? "")
        if #available(macOS 11.0, *), (action["style"] as? String) == "destructive" {
          button.hasDestructiveAction = true
        }
        button.isEnabled = action["enabled"] as? Bool ?? true
      }
    }

    let response = alert.runModal()
    result(Int(response.rawValue) - Int(NSApplication.ModalResponse.alertFirstButtonReturn.rawValue))
  }
}
