import SpriteKit
import UIKit

/// Penalty-Schießen: Der Spieler wischt den Puck Richtung Tor, ein Torwart bewegt sich hin und her.
/// Grafiken: Liegen „penalty_goalie“ und „penalty_puck“ in den Assets, werden sie verwendet,
/// sonst einfache Formen als Platzhalter.
final class PenaltyScene: SKScene {
    var totalShots = 5
    /// Torbreite als Anteil der Bildschirmbreite.
    var goalWidthFraction: CGFloat = 0.5
    /// Torwart-Tempo in Bildschirmbreiten pro Sekunde.
    var goalieSpeedFraction: CGFloat = 0.7
    /// Wird einmal mit der Zahl der Tore aufgerufen, wenn alle Schüsse vorbei sind.
    var onFinish: ((Int) -> Void)?

    private let crease = SKShapeNode()
    private let goalFrame = SKShapeNode()
    private let infoLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let hintLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var goalie = SKNode()
    private var puck = SKNode()
    private var shotDots: [SKShapeNode] = []

    private var goals = 0
    private var shotsTaken = 0
    private var goalieX: CGFloat = 0
    private var goalieDirection: CGFloat = 1
    private var goalieSpeedFactor: CGFloat = 1
    private var touchStart: CGPoint?
    private var puckVelocity: CGVector?
    private var lastUpdate: TimeInterval = 0
    private var currentTime: TimeInterval = 0
    private var nextShotAt: TimeInterval?
    private var finishAt: TimeInterval?
    private var isBuilt = false
    private var didReportFinish = false

    private var puckRadius: CGFloat { max(12, size.width * 0.035) }
    private var goalWidth: CGFloat { size.width * goalWidthFraction }
    private var goalLineY: CGFloat { size.height * 0.72 }
    private var goalieSize: CGSize { CGSize(width: size.width * 0.17, height: size.width * 0.19) }
    private var puckStart: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.2) }
    private var goalieMinX: CGFloat { size.width / 2 - goalWidth / 2 + goalieSize.width / 2 }
    private var goalieMaxX: CGFloat { size.width / 2 + goalWidth / 2 - goalieSize.width / 2 }

    // MARK: - Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1)
        guard !isBuilt else { return }
        isBuilt = true
        addChild(crease)
        addChild(goalFrame)
        for label in [infoLabel, scoreLabel, hintLabel] {
            label.fontColor = UIColor(red: 0.08, green: 0.15, blue: 0.3, alpha: 1)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 10
            addChild(label)
        }
        infoLabel.alpha = 0
        hintLabel.text = L("penalty.hint")
        goalieX = size.width / 2
        layoutNodes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if isBuilt && size.width > 0 && size.height > 0 {
            layoutNodes()
        }
    }

    /// Baut alle größenabhängigen Elemente neu auf (beim Start und wenn sich die Größe ändert).
    private func layoutNodes() {
        let midX = size.width / 2

        let creasePath = CGMutablePath()
        creasePath.addArc(center: CGPoint(x: midX, y: goalLineY), radius: goalWidth * 0.65,
                          startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
        creasePath.closeSubpath()
        crease.path = creasePath
        crease.fillColor = UIColor.systemBlue.withAlphaComponent(0.18)
        crease.strokeColor = UIColor.systemRed.withAlphaComponent(0.6)
        crease.lineWidth = 2

        let goalHeight = size.height * 0.07
        goalFrame.path = CGPath(rect: CGRect(x: midX - goalWidth / 2, y: goalLineY, width: goalWidth, height: goalHeight), transform: nil)
        goalFrame.fillColor = UIColor.white.withAlphaComponent(0.9)
        goalFrame.strokeColor = .systemRed
        goalFrame.lineWidth = 5

        goalie.removeFromParent()
        goalie = makeNode(imageNamed: "penalty_goalie", size: goalieSize) {
            let body = SKShapeNode(rectOf: self.goalieSize, cornerRadius: 10)
            body.fillColor = UIColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1)
            body.strokeColor = UIColor(red: 0.5, green: 0.05, blue: 0.05, alpha: 1)
            body.lineWidth = 3
            return body
        }
        goalie.zPosition = 5
        goalieX = min(max(goalieX, goalieMinX), goalieMaxX)
        goalie.position = CGPoint(x: goalieX, y: goalLineY + goalieSize.height * 0.15)
        addChild(goalie)

        puck.removeFromParent()
        let puckSize = CGSize(width: puckRadius * 2, height: puckRadius * 2)
        puck = makeNode(imageNamed: "penalty_puck", size: puckSize) {
            let disc = SKShapeNode(circleOfRadius: self.puckRadius)
            disc.fillColor = .black
            disc.strokeColor = .darkGray
            return disc
        }
        puck.zPosition = 6
        puck.position = puckStart
        addChild(puck)
        puckVelocity = nil

        scoreLabel.fontSize = 26
        scoreLabel.position = CGPoint(x: midX, y: size.height * 0.9)
        infoLabel.fontSize = 44
        infoLabel.position = CGPoint(x: midX, y: size.height * 0.47)
        hintLabel.fontSize = 18
        hintLabel.position = CGPoint(x: midX, y: size.height * 0.09)

        shotDots.forEach { $0.removeFromParent() }
        shotDots = (0..<totalShots).map { index in
            let dot = SKShapeNode(circleOfRadius: 9)
            let spacing: CGFloat = 28
            let startX = midX - spacing * CGFloat(totalShots - 1) / 2
            dot.position = CGPoint(x: startX + spacing * CGFloat(index), y: size.height * 0.85)
            dot.strokeColor = .gray
            dot.lineWidth = 2
            addChild(dot)
            return dot
        }
        refreshScore()
    }

    private func makeNode(imageNamed name: String, size: CGSize, fallback: () -> SKNode) -> SKNode {
        if UIImage(named: name) != nil {
            let sprite = SKSpriteNode(imageNamed: name)
            sprite.size = size
            return sprite
        }
        return fallback()
    }

    private func refreshScore() {
        scoreLabel.text = LF("penalty.score", Fmt.integer(goals), Fmt.integer(totalShots))
    }

    // MARK: - Eingabe

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard canShoot, let touch = touches.first else { return }
        touchStart = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard canShoot, let start = touchStart, let touch = touches.first else { return }
        touchStart = nil
        let end = touch.location(in: self)
        let dx = end.x - start.x
        let dy = end.y - start.y
        // Nur Wischbewegungen nach oben zählen als Schuss.
        guard dy > 20 else { return }
        let length = hypot(dx, dy)
        let speed = size.height * 1.4
        puckVelocity = CGVector(dx: dx / length * speed, dy: dy / length * speed)
        hintLabel.isHidden = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = nil
    }

    private var canShoot: Bool {
        isBuilt && puckVelocity == nil && nextShotAt == nil && finishAt == nil && shotsTaken < totalShots
    }

    // MARK: - Spielablauf

    override func update(_ time: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : CGFloat(min(time - lastUpdate, 1.0 / 20.0))
        lastUpdate = time
        currentTime = time
        guard isBuilt else { return }

        moveGoalie(dt)

        if let velocity = puckVelocity {
            puck.position = CGPoint(x: puck.position.x + velocity.dx * dt, y: puck.position.y + velocity.dy * dt)
            if puck.position.y >= goalLineY {
                resolveShot()
            } else if puck.position.x < -puckRadius || puck.position.x > size.width + puckRadius {
                resolveShot()
            }
        }

        if let due = nextShotAt, time >= due {
            nextShotAt = nil
            prepareNextShot()
        }

        if let due = finishAt, time >= due, !didReportFinish {
            didReportFinish = true
            onFinish?(goals)
        }
    }

    private func moveGoalie(_ dt: CGFloat) {
        guard goalieMaxX > goalieMinX else { return }
        goalieX += goalieDirection * goalieSpeedFraction * goalieSpeedFactor * size.width * dt
        if goalieX >= goalieMaxX {
            goalieX = goalieMaxX
            goalieDirection = -1
            goalieSpeedFactor = CGFloat.random(in: 0.8...1.2)
        } else if goalieX <= goalieMinX {
            goalieX = goalieMinX
            goalieDirection = 1
            goalieSpeedFactor = CGFloat.random(in: 0.8...1.2)
        }
        goalie.position.x = goalieX
    }

    private func resolveShot() {
        puckVelocity = nil
        let x = puck.position.x
        let midX = size.width / 2
        let inGoal = abs(x - midX) <= goalWidth / 2 - puckRadius * 0.5 && puck.position.y >= goalLineY
        let saved = abs(x - goalie.position.x) <= goalieSize.width / 2 + puckRadius * 0.6
        let scored = inGoal && !saved

        if scored { goals += 1 }
        if shotDots.indices.contains(shotsTaken) {
            shotDots[shotsTaken].fillColor = scored ? .systemGreen : .systemRed
        }
        shotsTaken += 1
        refreshScore()

        let text = scored ? L("penalty.goal") : (inGoal ? L("penalty.saved") : L("penalty.miss"))
        flash(text, color: scored ? .systemGreen : .systemRed)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(scored ? .success : .error)

        if shotsTaken >= totalShots {
            finishAt = currentTime + 1.6
            infoLabel.removeAllActions()
            infoLabel.text = LF("penalty.final", Fmt.integer(goals), Fmt.integer(totalShots))
            infoLabel.fontColor = UIColor(red: 0.08, green: 0.15, blue: 0.3, alpha: 1)
            infoLabel.alpha = 1
            infoLabel.setScale(1)
        } else {
            nextShotAt = currentTime + 0.9
        }
    }

    private func prepareNextShot() {
        puck.position = puckStart
        puck.alpha = 0
        puck.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func flash(_ text: String, color: UIColor) {
        infoLabel.removeAllActions()
        infoLabel.text = text
        infoLabel.fontColor = color
        infoLabel.alpha = 1
        infoLabel.setScale(0.6)
        infoLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeOut(withDuration: 0.25)
        ]))
    }
}
