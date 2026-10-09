import Foundation

/// Local, rule-based "Wait." check. Scams that target older people almost always need the victim to
/// share their screen, install a remote-access app, or read out a one-time code. Gabay never needs any
/// of those, so when a goal or a step leads there, it pauses and says so (it doesn't diagnose scams).
enum ScamGuard {
    static let remoteApps = ["anydesk", "teamviewer", "rustdesk", "quick assist", "quickassist", "ultraviewer",
                             "supremo", "remote desktop", "remotepc", "splashtop", "zoho assist", "screenconnect",
                             "logmein", "chrome remote desktop"]
    static let shareScreen = ["share screen", "share my screen", "share your screen", "screen share", "screen sharing",
                              "ishare ang screen", "i-share ang screen", "share ng screen", "start sharing", "present now"]
    static let otp = ["otp", "one-time pin", "one time pin", "one-time password", "one time password", "verification code",
                      "6-digit code", "mpin"]
    static let requester = ["bank", "bangko", "gcash", "maya", "sss", "philhealth", "pag-ibig", "pagibig", "bir", "egov",
                            "government", "gobyerno", "agent", "support", "technician", "microsoft", "apple support", "police"]

    struct Warning { let text: String; let hint: String }

    /// Checks the person's goal before anything is pointed at.
    static func check(goal: String) -> Warning? {
        let g = goal.lowercased()
        if remoteApps.contains(where: g.contains) {
            return Warning(text: "Wait. Real banks and government offices never ask you to install apps like this.",
                           hint: "Apps like AnyDesk let a stranger control your computer. If someone on the phone asked you to, hang up and call your family.")
        }
        if shareScreen.contains(where: g.contains), requester.contains(where: g.contains) {
            return Warning(text: "Wait. Real banks and government offices never ask you to share your screen.",
                           hint: "If someone asked you to, stop and call your family first. Gabay can show you the steps without anyone seeing your screen.")
        }
        if otp.contains(where: g.contains), (g.contains("send") || g.contains("give") || g.contains("ibigay") || g.contains("tell")) {
            return Warning(text: "Wait. Never give your one-time code to anyone.",
                           hint: "Not even someone who says they're from your bank. Your code is like a key to your money.")
        }
        return nil
    }

    /// Checks the control Gabay is about to point at (e.g. a "Share screen" or "Download AnyDesk" button).
    static func check(label: String) -> Warning? {
        let l = label.lowercased()
        if remoteApps.contains(where: l.contains) {
            return Warning(text: "Wait. This would let someone else control your computer.",
                           hint: "Real banks and government offices never ask for this. If someone told you to do it, call your family first.")
        }
        if shareScreen.contains(where: l.contains) {
            return Warning(text: "Wait. This shares your screen with the other person.",
                           hint: "Only do this with family you called yourself. Never for someone who says they're from a bank or the government.")
        }
        return nil
    }
}
