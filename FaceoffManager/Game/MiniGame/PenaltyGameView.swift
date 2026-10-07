import SpriteKit
import SwiftUI

/// Vollbild für das Penalty-Schießen. `onFinish(nil)` bedeutet: übersprungen bzw. abgebrochen.
struct PenaltyGameView: View {
    let session: PenaltySession
    let onFinish: (Int?) -> Void
    @State private var scene: PenaltyScene

    init(session: PenaltySession, onFinish: @escaping (Int?) -> Void) {
        self.session = session
        self.onFinish = onFinish
        let scene = PenaltyScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        scene.totalShots = session.shots
        scene.goalWidthFraction = CGFloat(session.goalWidth)
        scene.goalieSpeedFraction = CGFloat(session.goalieSpeed)
        scene.onFinish = { goals in onFinish(goals) }
        _scene = State(initialValue: scene)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            Button(session.mode == .match ? L("penalty.skipMatch") : L("penalty.quit")) {
                onFinish(nil)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .statusBarHidden()
    }
}
