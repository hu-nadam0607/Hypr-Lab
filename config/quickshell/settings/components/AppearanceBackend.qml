import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property int borderSize: 2
    property int rounding: 2
    property real activeOpacity: 0.80
    property real inactiveOpacity: 0.70
    property bool shadowEnabled: true
    property bool blurEnabled: true
    property int blurSize: 4
    property int blurPasses: 3
    property bool animationsEnabled: true
    property int gapsIn: 10
    property int gapsOut: 10
    property string statusText: "Ready"

    readonly property string helper: Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh"

    function setValue(key, value): void {
        Quickshell.execDetached(["bash", helper, "set", key, String(value)])
        statusText = "Applied"
        statusTimer.restart()
    }
    function clamp(v,a,b) { return Math.max(a,Math.min(b,v)) }
    function reload(): void { if (!loadProc.running) loadProc.running = true }

    Process {
        id: loadProc
        command: ["bash", root.helper, "dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (let line of text.trim().split("\n")) {
                    const i=line.indexOf("="); if(i<1) continue
                    const k=line.slice(0,i), v=line.slice(i+1)
                    if(k==="BORDER_SIZE") root.borderSize=parseInt(v)
                    else if(k==="ROUNDING") root.rounding=parseInt(v)
                    else if(k==="ACTIVE_OPACITY") root.activeOpacity=parseFloat(v)
                    else if(k==="INACTIVE_OPACITY") root.inactiveOpacity=parseFloat(v)
                    else if(k==="SHADOW") root.shadowEnabled=v==="1"
                    else if(k==="BLUR") root.blurEnabled=v==="1"
                    else if(k==="BLUR_SIZE") root.blurSize=parseInt(v)
                    else if(k==="BLUR_PASSES") root.blurPasses=parseInt(v)
                    else if(k==="ANIMATIONS") root.animationsEnabled=v==="1"
                    else if(k==="GAPS_IN") root.gapsIn=parseInt(v)
                    else if(k==="GAPS_OUT") root.gapsOut=parseInt(v)
                }
            }
        }
    }
    Timer { id:statusTimer; interval:1400; repeat:false; onTriggered:root.statusText="Ready" }
    Component.onCompleted: reload()
}
