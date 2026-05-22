import AppKit

let isLogin = CommandLine.arguments.contains("--login")
if isLogin {
    NSApplication.shared.setActivationPolicy(.prohibited)
}

StaggeredApp.main()
