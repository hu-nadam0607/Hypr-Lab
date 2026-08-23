import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string osName: "Loading…"
    property string uptime: "Loading…"
    property string kernel: "Loading…"
    property string memory: "Loading…"
    property string cpu: "Loading…"
    property string gpu: "Loading…"
    property string hdd: "—"
    property string ssd: "—"
    property string nvme: "—"
    property string monitors: "Loading…"

    property string statusText: "Ready"

    function refresh(): void {
        if (!probe.running) {
            root.statusText = "Refreshing"
            probe.running = true
        }
    }

    function setField(key, value): void {
        if (key === "OS") root.osName = value
        else if (key === "UPTIME") root.uptime = value
        else if (key === "KERNEL") root.kernel = value
        else if (key === "MEMORY") root.memory = value
        else if (key === "CPU") root.cpu = value
        else if (key === "GPU") root.gpu = value
        else if (key === "HDD") root.hdd = value.length ? value : "—"
        else if (key === "SSD") root.ssd = value.length ? value : "—"
        else if (key === "NVME") root.nvme = value.length ? value : "—"
        else if (key === "MONITOR") root.monitors = value
    }

    Process {
        id: probe

        command: [
            "bash",
            "-lc",
            "set +e; " +
            "os=$(awk -F= '/^PRETTY_NAME=/{v=$2; gsub(/^\\\"|\\\"$/,\"\",v); print v}' /etc/os-release | head -n1); " +
            "up=$(uptime -p 2>/dev/null | sed 's/^up //'); " +
            "ker=$(uname -r 2>/dev/null); " +
            "mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 \" / \" $2}'); " +
            "cpu=$(lscpu 2>/dev/null | awk -F: '/Model name:/ {sub(/^[ \\t]+/,\"\",$2); print $2; exit}'); " +
            "gpu=$(lspci 2>/dev/null | awk -F': ' '/VGA compatible controller|3D controller|Display controller/ {print $2}' | paste -sd ';' -); " +
            "hdd=$(lsblk -dn -o NAME,TYPE,ROTA,SIZE,MODEL 2>/dev/null | awk '$2==\"disk\" && $3==1 {name=$1;size=$4;$1=$2=$3=$4=\"\";sub(/^[ \\t]+/,\"\",$0); printf \"%s %s %s;\",name,size,$0}' | sed 's/;$//'); " +
            "nvme=$(lsblk -dn -o NAME,TYPE,ROTA,SIZE,MODEL 2>/dev/null | awk '$2==\"disk\" && $1 ~ /^nvme/ {name=$1;size=$4;$1=$2=$3=$4=\"\";sub(/^[ \\t]+/,\"\",$0); printf \"%s %s %s;\",name,size,$0}' | sed 's/;$//'); " +
            "ssd=$(lsblk -dn -o NAME,TYPE,ROTA,SIZE,MODEL 2>/dev/null | awk '$2==\"disk\" && $3==0 && $1 !~ /^nvme/ {name=$1;size=$4;$1=$2=$3=$4=\"\";sub(/^[ \\t]+/,\"\",$0); printf \"%s %s %s;\",name,size,$0}' | sed 's/;$//'); " +
            "if command -v jq >/dev/null 2>&1; then " +
            "mon=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | ((.description // .name) + \" · \" + ((.width|tostring) + \"x\" + (.height|tostring)) + \" @ \" + (((.refreshRate // 0)|round|tostring)) + \"Hz · scale \" + ((.scale // 1)|tostring))] | join(\"; \")'); " +
            "else mon=$(hyprctl monitors 2>/dev/null | awk '/^Monitor /{printf \"%s;\",$2}' | sed 's/;$//'); fi; " +
            "printf 'OS|%s\\nUPTIME|%s\\nKERNEL|%s\\nMEMORY|%s\\nCPU|%s\\nGPU|%s\\nHDD|%s\\nSSD|%s\\nNVME|%s\\nMONITOR|%s\\n' " +
            "\"${os:-Unknown}\" \"${up:-Unknown}\" \"${ker:-Unknown}\" \"${mem:-Unknown}\" \"${cpu:-Unknown}\" \"${gpu:-Unknown}\" \"${hdd:-}\" \"${ssd:-}\" \"${nvme:-}\" \"${mon:-Unknown}\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text).trim().split("\n")

                for (let line of lines) {
                    const p = line.indexOf("|")
                    if (p < 1)
                        continue

                    root.setField(line.slice(0, p), line.slice(p + 1))
                }

                root.statusText = "Ready"
            }
        }
    }

    Component.onCompleted: root.refresh()
}
