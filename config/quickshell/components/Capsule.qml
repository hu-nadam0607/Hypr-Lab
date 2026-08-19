import QtQuick

Item {
    id: capsule

    property int capsuleWidth: 240
    property real capsuleHeight: 36
    property int capsuleRadius: 2 // compatibility with older callers; geometry is intentionally sharp

    property color capsuleColor: Qt.rgba(5 / 255, 9 / 255, 14 / 255, 0.28)
    property color borderColor: Qt.rgba(104 / 255, 120 / 255, 125 / 255, 0.80)
    property real borderWidth: 2.0

    // Closed 36px bars use a 16px slant. When a surface grows vertically
    // (CenterIsland), the slant grows with it instead of becoming visually vertical.
    // Width-limiting prevents the two sides from ever collapsing into each other.
    property real slant: Math.max(10, Math.min(capsuleWidth * 0.25, capsuleHeight * (16 / 36)))
    property int shadowDepth: 8
    property real shadowStrength: 0.38

    width: capsuleWidth
    height: capsuleHeight

    function requestRepaint(): void {
        glassCanvas.requestPaint()
    }

    onCapsuleWidthChanged: requestRepaint()
    onCapsuleHeightChanged: requestRepaint()
    onCapsuleColorChanged: requestRepaint()
    onBorderColorChanged: requestRepaint()
    onBorderWidthChanged: requestRepaint()
    onSlantChanged: requestRepaint()
    onShadowDepthChanged: requestRepaint()
    onShadowStrengthChanged: requestRepaint()

    Canvas {
        id: glassCanvas

        x: 0
        y: 0
        width: capsule.width
        height: capsule.height + capsule.shadowDepth
        antialiasing: true

        function panelPath(ctx, yOffset) {
            const w = capsule.width
            const h = capsule.height
            const s = Math.min(capsule.slant, Math.max(1, w / 4))

            ctx.beginPath()
            ctx.moveTo(s, yOffset)
            ctx.lineTo(w, yOffset)
            ctx.lineTo(w - s, h + yOffset)
            ctx.lineTo(0, h + yOffset)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = capsule.height
            const s = Math.min(capsule.slant, Math.max(1, w / 4))

            ctx.clearRect(0, 0, width, height)

            // Soft lower shadow: several translucent copies keep it subtle and avoid a second "bubble".
            const shadowSteps = [
                [2, capsule.shadowStrength * 0.38],
                [3, capsule.shadowStrength * 0.24],
                [5, capsule.shadowStrength * 0.12]
            ]

            for (let i = 0; i < shadowSteps.length; ++i) {
                panelPath(ctx, shadowSteps[i][0])
                ctx.fillStyle = Qt.rgba(0, 0, 0, shadowSteps[i][1])
                ctx.fill()
            }

            // Transparent material base; Hyprland's layer blur supplies the frosted background.
            panelPath(ctx, 0)
            ctx.fillStyle = capsule.capsuleColor
            ctx.fill()

            // Native 3D glass shading: bright top surface, neutral middle, darker lower edge.
            const material = ctx.createLinearGradient(0, 0, 0, h)
            material.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.16))
            material.addColorStop(0.18, Qt.rgba(1, 1, 1, 0.055))
            material.addColorStop(0.52, Qt.rgba(1, 1, 1, 0.012))
            material.addColorStop(0.82, Qt.rgba(0, 0, 0, 0.07))
            material.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.22))

            panelPath(ctx, 0)
            ctx.fillStyle = material
            ctx.fill()

            // Adaptive accent outline. Keep the entire stroke inside the item so the
            // bottom edge remains a true 2px even when the parent clips at bar height.
            const bi = Math.max(0.5, capsule.borderWidth / 2)
            ctx.beginPath()
            ctx.moveTo(s + bi, bi)
            ctx.lineTo(w - bi, bi)
            ctx.lineTo(w - s - bi, h - bi)
            ctx.lineTo(bi, h - bi)
            ctx.closePath()
            ctx.lineWidth = capsule.borderWidth
            ctx.strokeStyle = capsule.borderColor
            ctx.stroke()

            // Fine top highlight gives the 18px surface a tangible glass edge.
            ctx.beginPath()
            ctx.moveTo(s + 1, 1)
            ctx.lineTo(w - 1, 1)
            ctx.lineWidth = 0.7
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20)
            ctx.stroke()
        }
    }
}
