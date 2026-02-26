import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        // setup host api
        let api = DarwinHostApiImpl()
        DarwinHostApiSetup.setUp(binaryMessenger: flutterViewController.engine.binaryMessenger, api: api)

        
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        super.awakeFromNib()
    }
}
