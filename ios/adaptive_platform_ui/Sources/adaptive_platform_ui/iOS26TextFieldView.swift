import Flutter
import UIKit

/// Factory for creating native text field platform views
class iOS26TextFieldViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26TextFieldView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Native single-line text field.
///
/// `style: "plain"` wraps a UITextField, `style: "search"` wraps a
/// UISearchTextField (magnifier + clear button + system fill for free).
class iOS26TextFieldView: NSObject, FlutterPlatformView, UITextFieldDelegate {
    private var _view: UIView
    private var textField: UITextField!
    private var channel: FlutterMethodChannel
    private var fieldId: Int

    // Configuration
    private var initialText: String = ""
    private var placeholder: String = ""
    private var fieldStyle: String = "plain"
    private var fontSize: CGFloat = 17.0
    private var textColor: UIColor?
    private var placeholderColor: UIColor?
    private var backgroundColor: UIColor?
    private var cornerRadius: CGFloat?
    private var keyboardTypeName: String = "text"
    private var returnKeyName: String = "done"
    private var autocorrect: Bool = true
    private var obscureText: Bool = false
    private var isEnabled: Bool = true
    private var isDark: Bool = false
    private var autofocus: Bool = false

    /// Guards the echo loop: text pushed from Dart must not be reported back.
    private var suppressChangeEvent: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        // Contain the field's glass/shadow layers: without clipping they can
        // bleed outside the Flutter slot and leave artifacts over siblings.
        _view.clipsToBounds = true

        if let config = args as? [String: Any] {
            fieldId = config["id"] as? Int ?? 0
            initialText = config["text"] as? String ?? ""
            placeholder = config["placeholder"] as? String ?? ""
            fieldStyle = config["style"] as? String ?? "plain"
            if let size = config["fontSize"] as? Double { fontSize = CGFloat(size) }
            if let hex = config["textColor"] as? String { textColor = UIColor(hexString: hex) }
            if let hex = config["placeholderColor"] as? String { placeholderColor = UIColor(hexString: hex) }
            if let hex = config["backgroundColor"] as? String { backgroundColor = UIColor(hexString: hex) }
            if let radius = config["cornerRadius"] as? Double { cornerRadius = CGFloat(radius) }
            keyboardTypeName = config["keyboardType"] as? String ?? "text"
            returnKeyName = config["returnKeyType"] as? String ?? "done"
            autocorrect = config["autocorrect"] as? Bool ?? true
            obscureText = config["obscureText"] as? Bool ?? false
            isEnabled = config["enabled"] as? Bool ?? true
            isDark = config["isDark"] as? Bool ?? false
            autofocus = config["autofocus"] as? Bool ?? false
        } else {
            fieldId = 0
        }

        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_text_field_\(fieldId)",
            binaryMessenger: messenger
        )

        super.init()

        createNativeTextField()

        if #available(iOS 13.0, *) {
            _view.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func createNativeTextField() {
        if fieldStyle == "search", #available(iOS 13.0, *) {
            textField = UISearchTextField()
        } else {
            textField = UITextField()
        }

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = initialText
        textField.font = UIFont.systemFont(ofSize: fontSize)
        textField.keyboardType = keyboardType(from: keyboardTypeName)
        textField.returnKeyType = returnKey(from: returnKeyName)
        // Search fields never autocorrect or auto-capitalize.
        if fieldStyle == "search" {
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.spellCheckingType = .no
        } else {
            textField.autocorrectionType = autocorrect ? .yes : .no
        }
        textField.isSecureTextEntry = obscureText
        textField.isEnabled = isEnabled
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        if let color = textColor { textField.textColor = color }
        if let bg = backgroundColor { textField.backgroundColor = bg }
        if let radius = cornerRadius {
            textField.layer.cornerRadius = radius
            textField.layer.cornerCurve = .continuous
            textField.clipsToBounds = true
        }

        updatePlaceholder()

        // Flat appearance: no drop shadow on the field or the system
        // background subviews (iOS 26 renders search fields with an
        // elevated glass shadow by default).
        textField.layer.shadowOpacity = 0
        DispatchQueue.main.async { [weak self] in
            self?.removeSubviewShadows()
        }

        _view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            textField.topAnchor.constraint(equalTo: _view.topAnchor),
            textField.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
        ])

        if autofocus {
            DispatchQueue.main.async { [weak self] in
                self?.textField.becomeFirstResponder()
            }
        }
    }

    private func removeSubviewShadows() {
        func strip(_ view: UIView) {
            view.layer.shadowOpacity = 0
            view.layer.shadowColor = nil
            for sub in view.subviews { strip(sub) }
        }
        strip(textField)
    }

    private func updatePlaceholder() {
        if let color = placeholderColor {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: color, .font: UIFont.systemFont(ofSize: fontSize)]
            )
        } else {
            textField.placeholder = placeholder
        }
    }

    private func keyboardType(from name: String) -> UIKeyboardType {
        switch name {
        case "email": return .emailAddress
        case "number": return .numberPad
        case "phone": return .phonePad
        case "decimal": return .decimalPad
        case "url": return .URL
        default: return .default
        }
    }

    private func returnKey(from name: String) -> UIReturnKeyType {
        switch name {
        case "search": return .search
        case "send": return .send
        case "next": return .next
        case "go": return .go
        default: return .done
        }
    }

    @objc private func editingChanged() {
        if suppressChangeEvent { return }
        channel.invokeMethod("textChanged", arguments: ["text": textField.text ?? ""])
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        channel.invokeMethod("submitted", arguments: ["text": textField.text ?? ""])
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        channel.invokeMethod("focusChanged", arguments: ["focused": true])
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        channel.invokeMethod("focusChanged", arguments: ["focused": false])
    }

    // MARK: - Method channel

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setText":
            if let args = call.arguments as? [String: Any], let text = args["text"] as? String {
                suppressChangeEvent = true
                textField.text = text
                suppressChangeEvent = false
            }
            result(nil)
        case "setEnabled":
            if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
                textField.isEnabled = enabled
            }
            result(nil)
        case "setPlaceholder":
            if let args = call.arguments as? [String: Any], let text = args["placeholder"] as? String {
                placeholder = text
                updatePlaceholder()
            }
            result(nil)
        case "focus":
            textField.becomeFirstResponder()
            result(nil)
        case "unfocus":
            textField.resignFirstResponder()
            result(nil)
        case "setBrightness":
            if let args = call.arguments as? [String: Any], let dark = args["isDark"] as? Bool {
                isDark = dark
                if #available(iOS 13.0, *) {
                    _view.overrideUserInterfaceStyle = dark ? .dark : .light
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
