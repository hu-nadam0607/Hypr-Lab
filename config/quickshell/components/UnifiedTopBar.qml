import QtQuick

// Hypr-Lab v1.5 unified TopBar material.
//
// One continuous frosted-glass face, flush with the monitor top edge.
// The left and right ends keep the Hypr-Lab angled/parallelogram geometry,
// but ONLY the bottom edge receives the wallpaper-adaptive 2px accent border.
//
// All CenterIsland / LeftBar / RightBar logic remains outside this component.
Item {
    id: root

    property real barHeight: 36
    property color accentColor: "#68787D"
    property color surfaceColor: Qt.rgba(5 / 255, 9 / 255, 14 / 255, 0.28)
    property real borderWidth: 2.0

    // Keep the material away from the physical monitor edges, matching the
    // original Hypr-Lab left/right module spacing.
    property real endMargin: 8.0

    // Same visual slope family used by the expandable RightBar surfaces.
    property real slant: 14.0

    width: parent ? parent.width : 0
    height: barHeight

    function repaint(): void {
        canvas.requestPaint()
    }

    onWidthChanged: repaint()
    onHeightChanged: repaint()
    onBarHeightChanged: repaint()
    onAccentColorChanged: repaint()
    onSurfaceColorChanged: repaint()
    onBorderWidthChanged: repaint()
    onEndMarginChanged: repaint()
    onSlantChanged: repaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        function materialPath(ctx) {
            const w = width
            const h = root.barHeight
            const m = Math.max(0, root.endMargin)
            const s = Math.max(0, Math.min(root.slant, (w - m * 2) / 4))

            // A1/A2 reference geometry:
            // left  edge: bottom starts farther left than the top  (/)
            // right edge: top    ends farther right than the bottom (/)
            //
            // This makes one continuous parallelogram-like TopBar surface.
            ctx.beginPath()
            ctx.moveTo(m + s, 0)
            ctx.lineTo(w - m, 0)
            ctx.lineTo(w - m - s, h)
            ctx.lineTo(m, h)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = root.barHeight
            const m = Math.max(0, root.endMargin)
            const s = Math.max(0, Math.min(root.slant, (w - m * 2) / 4))

            ctx.clearRect(0, 0, width, height)

            // Shared frosted material.
            materialPath(ctx)
            ctx.fillStyle = root.surfaceColor
            ctx.fill()

            // Glass shading remains inside the same angled shape.
            const material = ctx.createLinearGradient(0, 0, 0, h)
            material.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.15))
            material.addColorStop(0.18, Qt.rgba(1, 1, 1, 0.050))
            material.addColorStop(0.52, Qt.rgba(1, 1, 1, 0.010))
            material.addColorStop(0.84, Qt.rgba(0, 0, 0, 0.065))
            material.addColorStop(1.00, Qt.rgba(0, 0, 0, 0.20))

            materialPath(ctx)
            ctx.fillStyle = material
            ctx.fill()

            // IMPORTANT:
            // No border on the top edge.
            // No border on either slanted end.
            // The only accent stroke is the 2px bottom edge.
            const y = h - root.borderWidth / 2

            ctx.beginPath()
            ctx.moveTo(m, y)
            ctx.lineTo(w - m - s, y)
            ctx.lineWidth = root.borderWidth
            ctx.strokeStyle = Qt.rgba(
                root.accentColor.r,
                root.accentColor.g,
                root.accentColor.b,
                0.90
            )
            ctx.stroke()
        }
    }
}
