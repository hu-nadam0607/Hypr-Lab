import QtQuick

Item {
    id: root
    property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 0

            SectionLabel { width: parent.width; text: "WINDOWS"; accentColor: root.accentColor }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Border size"
                subtitle: "Hyprland window border"
                valueText: backend ? backend.borderSize + " px" : "—"
                onDecrease: {
                    if (!backend) return
                    backend.borderSize = backend.clamp(backend.borderSize - 1, 0, 8)
                    backend.setValue("BORDER_SIZE", backend.borderSize)
                }
                onIncrease: {
                    if (!backend) return
                    backend.borderSize = backend.clamp(backend.borderSize + 1, 0, 8)
                    backend.setValue("BORDER_SIZE", backend.borderSize)
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Corner radius"
                subtitle: "Hyprland window rounding"
                valueText: backend ? String(backend.rounding) : "—"
                onDecrease: {
                    if (!backend) return
                    backend.rounding = backend.clamp(backend.rounding - 1, 0, 40)
                    backend.setValue("ROUNDING", backend.rounding)
                }
                onIncrease: {
                    if (!backend) return
                    backend.rounding = backend.clamp(backend.rounding + 1, 0, 40)
                    backend.setValue("ROUNDING", backend.rounding)
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Active opacity"
                subtitle: "Focused window opacity"
                valueText: backend ? Math.round(backend.activeOpacity * 100) + "%" : "—"
                onDecrease: {
                    if (!backend) return
                    backend.activeOpacity = backend.clamp(
                        Math.round((backend.activeOpacity - 0.05) * 100) / 100,
                        0.25, 1.0
                    )
                    backend.setValue("ACTIVE_OPACITY", backend.activeOpacity.toFixed(2))
                }
                onIncrease: {
                    if (!backend) return
                    backend.activeOpacity = backend.clamp(
                        Math.round((backend.activeOpacity + 0.05) * 100) / 100,
                        0.25, 1.0
                    )
                    backend.setValue("ACTIVE_OPACITY", backend.activeOpacity.toFixed(2))
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Inactive opacity"
                subtitle: "Background window opacity"
                valueText: backend ? Math.round(backend.inactiveOpacity * 100) + "%" : "—"
                onDecrease: {
                    if (!backend) return
                    backend.inactiveOpacity = backend.clamp(
                        Math.round((backend.inactiveOpacity - 0.05) * 100) / 100,
                        0.20, 1.0
                    )
                    backend.setValue("INACTIVE_OPACITY", backend.inactiveOpacity.toFixed(2))
                }
                onIncrease: {
                    if (!backend) return
                    backend.inactiveOpacity = backend.clamp(
                        Math.round((backend.inactiveOpacity + 0.05) * 100) / 100,
                        0.20, 1.0
                    )
                    backend.setValue("INACTIVE_OPACITY", backend.inactiveOpacity.toFixed(2))
                }
            }

            SectionLabel { width: parent.width; text: "EFFECTS"; accentColor: root.accentColor }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Window shadows"
                subtitle: "Enable Hyprland shadows"
                checked: backend ? backend.shadowEnabled : false
                onToggled: function(value) {
                    if (!backend) return
                    backend.shadowEnabled = value
                    backend.setValue("SHADOW", value ? 1 : 0)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Blur"
                subtitle: "Enable compositor blur"
                checked: backend ? backend.blurEnabled : false
                onToggled: function(value) {
                    if (!backend) return
                    backend.blurEnabled = value
                    backend.setValue("BLUR", value ? 1 : 0)
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Blur size"
                subtitle: "Compositor blur radius"
                enabled: backend ? backend.blurEnabled : false
                valueText: backend ? String(backend.blurSize) : "—"
                onDecrease: {
                    if (!backend) return
                    backend.blurSize = backend.clamp(backend.blurSize - 1, 1, 20)
                    backend.setValue("BLUR_SIZE", backend.blurSize)
                }
                onIncrease: {
                    if (!backend) return
                    backend.blurSize = backend.clamp(backend.blurSize + 1, 1, 20)
                    backend.setValue("BLUR_SIZE", backend.blurSize)
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Blur passes"
                subtitle: "Number of blur passes"
                enabled: backend ? backend.blurEnabled : false
                valueText: backend ? String(backend.blurPasses) : "—"
                onDecrease: {
                    if (!backend) return
                    backend.blurPasses = backend.clamp(backend.blurPasses - 1, 1, 8)
                    backend.setValue("BLUR_PASSES", backend.blurPasses)
                }
                onIncrease: {
                    if (!backend) return
                    backend.blurPasses = backend.clamp(backend.blurPasses + 1, 1, 8)
                    backend.setValue("BLUR_PASSES", backend.blurPasses)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Animations"
                subtitle: "Hyprland window and workspace animations"
                checked: backend ? backend.animationsEnabled : false
                onToggled: function(value) {
                    if (!backend) return
                    backend.animationsEnabled = value
                    backend.setValue("ANIMATIONS", value ? 1 : 0)
                }
            }

            SectionLabel { width: parent.width; text: "SPACING"; accentColor: root.accentColor }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Inner gaps"
                subtitle: "Space between tiled windows"
                valueText: backend ? backend.gapsIn + " px" : "—"
                onDecrease: {
                    if (!backend) return
                    backend.gapsIn = backend.clamp(backend.gapsIn - 1, 0, 40)
                    backend.setValue("GAPS_IN", backend.gapsIn)
                }
                onIncrease: {
                    if (!backend) return
                    backend.gapsIn = backend.clamp(backend.gapsIn + 1, 0, 40)
                    backend.setValue("GAPS_IN", backend.gapsIn)
                }
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Outer gaps"
                subtitle: "Space around the workspace"
                valueText: backend ? backend.gapsOut + " px" : "—"
                onDecrease: {
                    if (!backend) return
                    backend.gapsOut = backend.clamp(backend.gapsOut - 1, 0, 60)
                    backend.setValue("GAPS_OUT", backend.gapsOut)
                }
                onIncrease: {
                    if (!backend) return
                    backend.gapsOut = backend.clamp(backend.gapsOut + 1, 0, 60)
                    backend.setValue("GAPS_OUT", backend.gapsOut)
                }
            }
        }
    }
}
