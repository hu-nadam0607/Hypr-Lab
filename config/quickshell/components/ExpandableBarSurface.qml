import QtQuick

Item {
    id: surface

    property real surfaceWidth: 1080
    property real barHeight: 36
    property real extensionWidth: 360
    property real extensionHeight: 118
    property real reveal: 0.0

    property color surfaceColor: Qt.rgba(5 / 255, 9 / 255, 14 / 255, 0.30)
    property color borderColor: Qt.rgba(104 / 255, 120 / 255, 125 / 255, 0.82)
    property real borderWidth: 2.0

    property real slant: 14
    property real shadowDepth: 8
    property real shadowStrength: 0.40
    // When embedded in the unified Hypr-Lab TopBar, the closed 36px bar face
    // is supplied by UnifiedTopBar. The expandable sheet remains unchanged.
    property bool unifiedTopBarMode: false

    readonly property real clampedReveal: Math.max(0, Math.min(1.08, reveal))
    readonly property real bodyHeight: barHeight + extensionHeight * clampedReveal
    readonly property real extensionLeft: Math.max(0, surfaceWidth - extensionWidth)

    width: surfaceWidth
    height: bodyHeight + shadowDepth

    function repaint(): void {
        canvas.requestPaint()
    }

    onSurfaceWidthChanged: repaint()
    onBarHeightChanged: repaint()
    onExtensionWidthChanged: repaint()
    onExtensionHeightChanged: repaint()
    onRevealChanged: repaint()
    onSurfaceColorChanged: repaint()
    onBorderColorChanged: repaint()
    onBorderWidthChanged: repaint()
    onSlantChanged: repaint()
    onShadowDepthChanged: repaint()
    onShadowStrengthChanged: repaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        function outerPath(ctx, yOffset) {
            const w = surface.surfaceWidth
            const bh = surface.barHeight
            const h = surface.bodyHeight
            const s = Math.min(surface.slant, Math.max(1, w / 5))
            const ex = surface.extensionLeft
            const r = surface.clampedReveal
            const drop = surface.extensionHeight * r

            // Preserve the exact bar angle while the material grows downward.
            // Both extension edges use the same slope as the closed RightBar,
            // so the opened shape never pinches, fans out or turns into a new trapezoid.
            const slope = s / Math.max(1, bh)
            const shift = slope * drop
            const extensionTopLeft = ex + s
            const extensionBottomLeft = extensionTopLeft - shift
            const extensionBottomRight = (w - s) - shift

            ctx.beginPath()
            ctx.moveTo(s, yOffset)
            ctx.lineTo(w, yOffset)
            ctx.lineTo(w - s, bh + yOffset)

            if (r > 0.001) {
                ctx.lineTo(extensionBottomRight, h + yOffset)
                ctx.lineTo(extensionBottomLeft, h + yOffset)
                ctx.lineTo(extensionTopLeft, bh + yOffset)
            }

            ctx.lineTo(0, bh + yOffset)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            const h = surface.bodyHeight
            const bh = surface.barHeight

            ctx.clearRect(0, 0, width, height)

            if (surface.unifiedTopBarMode) {
                if (surface.clampedReveal <= 0.001)
                    return
                // Keep the Noctalia-inspired expandable geometry exactly as-is,
                // but never repaint the shared closed TopBar face above it.
                ctx.save()
                ctx.beginPath()
                ctx.rect(0, surface.barHeight, width, height - surface.barHeight)
                ctx.clip()
            }

            // Fade the expandable-sheet shadow out *before* the spring reaches
            // the closed position. Without this, the material itself is already
            // clipped back into the unified TopBar while the positive shadow
            // offsets are still visible below barHeight, which looks like a
            // second RightBar layer "bouncing" on close.
            //
            // Keep the full shadow for normal/open states, but smoothly remove
            // it over the final ~14% of the closing travel.
            const shadowReveal = surface.unifiedTopBarMode
                ? Math.max(0.0, Math.min(1.0, surface.clampedReveal / 0.14))
                : 1.0

            const shadowSteps = [
                [2, surface.shadowStrength * 0.34 * shadowReveal],
                [4, surface.shadowStrength * 0.20 * shadowReveal],
                [7, surface.shadowStrength * 0.10 * shadowReveal]
            ]

            if (shadowReveal > 0.001) {
                for (let i = 0; i < shadowSteps.length; ++i) {
                    outerPath(ctx, shadowSteps[i][0])
                    ctx.fillStyle = Qt.rgba(0, 0, 0, shadowSteps[i][1])
                    ctx.fill()
                }
            }

            outerPath(ctx, 0)
            ctx.fillStyle = surface.surfaceColor
            ctx.fill()

            const material = ctx.createLinearGradient(0, 0, 0, Math.max(bh, h))
            material.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.17))
            material.addColorStop(0.13, Qt.rgba(1, 1, 1, 0.060))
            material.addColorStop(0.45, Qt.rgba(1, 1, 1, 0.010))
            material.addColorStop(0.78, Qt.rgba(0, 0, 0, 0.075))
            material.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.24))

            outerPath(ctx, 0)
            ctx.fillStyle = material
            ctx.fill()

            // Border handling differs in unified TopBar mode.
            //
            // The closed TopBar already owns the single 2px bottom accent line.
            // Stroking outerPath() here would repaint the long horizontal
            // barHeight segment (extensionTopLeft -> 0), which visually doubles
            // the TopBar border and makes the whole RightBar appear to shift
            // whenever Audio / Notifications / Control Center opens.
            //
            // In unified mode we therefore draw ONLY the three exposed edges of
            // the drop-down sheet: left slant, bottom edge and right slant.
            if (surface.unifiedTopBarMode) {
                const w = surface.surfaceWidth
                const bh = surface.barHeight
                const h = surface.bodyHeight
                const s = Math.min(surface.slant, Math.max(1, w / 5))
                const ex = surface.extensionLeft
                const r = surface.clampedReveal
                const drop = surface.extensionHeight * r
                const slope = s / Math.max(1, bh)
                const shift = slope * drop

                const topLeft = ex + s
                const bottomLeft = topLeft - shift
                const topRight = w - s
                const bottomRight = topRight - shift

                ctx.beginPath()
                ctx.moveTo(topLeft, bh + 0.5)
                ctx.lineTo(bottomLeft, h - 0.5)
                ctx.lineTo(bottomRight, h - 0.5)
                ctx.lineTo(topRight, bh + 0.5)

                ctx.lineWidth = surface.borderWidth
                ctx.strokeStyle = surface.borderColor
                ctx.stroke()
            } else {
                outerPath(ctx, 0.5)
                ctx.lineWidth = surface.borderWidth
                ctx.strokeStyle = surface.borderColor
                ctx.stroke()

                // Legacy standalone bar highlight.
                ctx.beginPath()
                ctx.moveTo(surface.slant + 1, 1)
                ctx.lineTo(surface.surfaceWidth - 1, 1)
                ctx.lineWidth = 0.75
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.22)
                ctx.stroke()
            }

            if (surface.unifiedTopBarMode)
                ctx.restore()
        }
    }
}
