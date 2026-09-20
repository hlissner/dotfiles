import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginComponent {
    id: root

    property var sysfsDevices: []
    // Keys currently below the critical line, so the notification fires on the
    // way down and not once a minute thereafter.
    property var _critical: ({})

    // Which device the popout is currently about, and a handle on the popout
    // itself. PluginPopout hands its content a `parentPopout`, which is the only
    // way up to shouldBeVisible from here -- PluginComponent keeps the popout
    // private and exposes no open state of its own. Without it a click that
    // dismissed the popout by other means would leave us out of sync.
    property string selectedKey: ""
    property var popoutRef: null
    readonly property bool popoutOpen: popoutRef ? popoutRef.shouldBeVisible : false

    // addr -> RSSI. BlueZ drops Device1.RSSI the moment a device connects (it's
    // an advertisement property), so the only reading left for a live link is
    // the HCI Read_RSSI command, which is what hcitool shells out to.
    property var rssiByAddr: ({})

    readonly property var iconRules: pluginData.deviceIcons ?? []
    readonly property var nameFilter: pluginData.deviceFilter ?? []
    readonly property bool showLabels: pluginData.showLabels === true
    readonly property int warnThreshold: Number(pluginData.warnThreshold ?? 20)
    readonly property int criticalThreshold: Number(pluginData.criticalThreshold ?? 10)
    // Above this, the meter is just noise in the bar; the icon carries it.
    readonly property int meterThreshold: Number(pluginData.meterThreshold ?? 100)
    readonly property bool notifyCritical: pluginData.notifyCritical !== false
    readonly property bool hideWhenEmpty: pluginData.hideWhenEmpty !== false

    // Theme.iconSize is the *dialog* size -- every bar widget runs it through
    // barIconSize first, which is why this one used to tower over its
    // neighbours. undefined offset means -6, the setting 33 of them use.
    readonly property real pillIconSize: Theme.barIconSize(barThickness, undefined,
                                                           barConfig?.maximizeWidgetIcons,
                                                           barConfig?.iconScale)

    // The old tooltip rode on a bare fontSizeSmall; the popout has room.
    readonly property real popoutFontSize: Theme.fontSizeSmall * 1.5
    // The technical half is reference material, not the headline.
    readonly property real detailFontSize: Theme.fontSizeSmall * 1.05

    // Half the row spacing inward, so adjacent entries tile with no sliver
    // between them; the pill's own padding outward, so there's no bare pill
    // left to click. That last part is what stops a near-miss falling through
    // to BasePill and reopening whichever device was up last. Mirrors
    // BasePill's horizontalPadding exactly -- overshooting would reach past the
    // pill and start eating the neighbouring widget's clicks.
    readonly property real hitSlopIn: Theme.spacingS / 2
    readonly property real hitSlopOut: (barConfig?.widgetPadding ?? 12) * (widgetThickness / 30)

    // BlueZ only reports batteries it's been told about, and on a bredr-only
    // controller that's fewer than you'd hope -- no LE means no GATT battery
    // service. sysfs knows about anything with a kernel HID driver. Neither
    // source is a superset of the other, so take both.
    readonly property var btStates: ["Disconnected", "Connected", "Disconnecting", "Connecting"]

    readonly property var btDevices: {
        const out = [];
        for (const d of (BluetoothService.allDevicesWithBattery || [])) {
            if (!d)
                continue;
            const details = [];
            const push = (label, value) => {
                if (value !== undefined && value !== null && value !== "")
                    details.push({ label: label, value: String(value) });
            };
            push("State", btStates[Number(d.state ?? 0)] || "Unknown");
            push("Paired", d.paired ? "yes" : "no");
            push("Bonded", d.bonded ? "yes" : "no");
            push("Trusted", d.trusted ? "yes" : "no");
            push("Class", d.icon);
            push("Adapter", d.adapter?.name || d.adapter?.adapterId);
            push("Source", "BlueZ");
            push("D-Bus path", d.dbusPath);

            out.push({
                name: String(d.name || d.deviceName || "Bluetooth"),
                address: String(d.address || ""),
                level: Math.max(0, Math.min(100, Math.round((d.battery || 0) * 100))),
                charging: false,   // BlueZ doesn't tell us; only sysfs does
                hint: String(d.icon || ""),
                details: details
            });
        }
        return out;
    }

    // 0005 is what a bluetooth-attached HID reports; the rest show up on the
    // wired peripherals that also carry a battery.
    function busName(code) {
        switch (String(code)) {
        case "0003": return "USB";
        case "0005": return "Bluetooth";
        case "0018": return "I2C";
        default: return "bus " + code;
        }
    }

    readonly property var devices: {
        const seen = {};
        const out = [];
        for (const d of btDevices) {
            seen[normalize(d.name)] = true;
            out.push(d);
        }
        // A device the kernel and BlueZ both know about shows up twice; BlueZ
        // wins, it updates without polling.
        for (const d of sysfsDevices) {
            if (!seen[normalize(d.name)])
                out.push(d);
        }
        return out.filter(matches).sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property bool hasDevices: devices.length > 0

    // One KEY=VALUE block per device, `--` between them. Not `grep -H`: these
    // paths have the device's MAC in them, so every line would carry colons
    // that no amount of splitting tells apart from the filename separator.
    // SCOPE is what separates a peripheral from the laptop's own battery.
    // The sibling device/uevent is where the interesting half lives -- driver,
    // HID ids, which adapter it's paired to -- so it comes along under a DEV_
    // prefix to keep the two namespaces apart.
    readonly property string probe:
        "for f in /sys/class/power_supply/*/uevent; do " +
        "[ -r \"$f\" ] || continue; cat \"$f\"; " +
        "d=$(dirname \"$f\")/device/uevent; " +
        "[ -r \"$d\" ] && sed 's/^/DEV_/' \"$d\"; " +
        "echo '--'; done 2>/dev/null"

    function normalize(s) {
        return String(s || "").trim().toLowerCase();
    }

    function matches(dev) {
        if (!nameFilter.length)
            return true;
        const name = normalize(dev.name);
        return nameFilter.some(f => name.includes(normalize(f)));
    }

    function parseSysfs(text) {
        const out = [];
        let p = {};

        const flush = () => {
            if (p.POWER_SUPPLY_SCOPE === "Device") {
                const level = Number(p.POWER_SUPPLY_CAPACITY ?? -1);
                if (!isNaN(level) && level >= 0) {
                    const raw = String(p.POWER_SUPPLY_NAME || "");
                    const mac = raw.match(/([0-9a-fA-F]{2}(?::[0-9a-fA-F]{2}){5})/);

                    const details = [];
                    const push = (label, value) => {
                        if (value !== undefined && value !== null && value !== "")
                            details.push({ label: label, value: String(value) });
                    };
                    push("Status", p.POWER_SUPPLY_STATUS);
                    push("Driver", p.DEV_DRIVER);
                    // "bus:vendor:product", all hex and generously zero-padded.
                    const hid = String(p.DEV_HID_ID || "").split(":");
                    if (hid.length === 3) {
                        push("Bus", busName(hid[0]));
                        push("Vendor:Product",
                             hid[1].slice(-4).toUpperCase() + ":" + hid[2].slice(-4).toUpperCase());
                    }
                    push("HID name", p.DEV_HID_NAME);
                    push("Host adapter", p.DEV_HID_PHYS);
                    push("Source", "sysfs");
                    push("Power supply", raw);

                    out.push({
                        name: String(p.POWER_SUPPLY_MODEL_NAME || raw || "Device"),
                        address: mac ? mac[1] : String(p.DEV_HID_UNIQ || ""),
                        level: Math.max(0, Math.min(100, Math.round(level))),
                        charging: (p.POWER_SUPPLY_STATUS || "Discharging") !== "Discharging",
                        hint: "",
                        details: details
                    });
                }
            }
            p = {};
        };

        for (const line of String(text || "").split("\n")) {
            if (line === "--") {
                flush();
                continue;
            }
            const eq = line.indexOf("=");
            if (eq > 0)
                p[line.slice(0, eq)] = line.slice(eq + 1);
        }
        flush();   // in case the last block came through unterminated
        return out;
    }

    function ruleFor(dev) {
        const name = normalize(dev.name);
        for (const rule of iconRules) {
            if (rule && rule.match && name.includes(normalize(rule.match)))
                return rule;
        }
        return null;
    }

    function iconFor(dev) {
        const rule = ruleFor(dev);
        if (rule && rule.icon)
            return String(rule.icon);

        // DMS's own guesser covers headset/mouse/keyboard/phone/watch/speaker/tv
        // off the BlueZ icon name. It has never heard of a trackpad.
        const hay = normalize(dev.name + " " + dev.hint);
        if (hay.includes("trackpad") || hay.includes("touchpad"))
            return "touch_app";
        if (hay.includes("controller") || hay.includes("gamepad")
            || hay.includes("dualsense") || hay.includes("dualshock"))
            return "sports_esports";
        if (hay.includes("stylus") || hay.includes("pen") || hay.includes("wacom"))
            return "stylus_note";

        return BluetoothService.getDeviceIcon({ name: dev.name, icon: dev.hint });
    }

    function colorFor(dev) {
        const rule = ruleFor(dev);
        if (rule && rule.color)
            return rule.color;
        if (dev.level <= criticalThreshold)
            return Theme.error;
        if (dev.charging)
            return Theme.primary;
        if (dev.level <= warnThreshold)
            return Theme.warning;
        return Theme.surfaceText;
    }

    function keyFor(dev) {
        return dev.address || normalize(dev.name);
    }

    function statusFor(dev) {
        return dev.level + "%" + (dev.charging ? " (charging)" : "");
    }

    function applyRssi(text) {
        const out = {};
        for (const line of String(text || "").split("\n")) {
            const parts = line.trim().split(/\s+/);
            if (parts.length !== 2)
                continue;
            const n = Number(parts[1]);
            if (!isNaN(n))
                out[normalize(parts[0])] = n;
        }
        rssiByAddr = out;
    }

    // On BR/EDR this is a delta from the golden receive power range rather than
    // absolute dBm, so the scale below is a feel-based mapping, not physics.
    // Nearer zero is stronger either way.
    function signalFor(dev) {
        if (!dev || !dev.address)
            return null;
        const rssi = rssiByAddr[normalize(dev.address)];
        if (rssi === undefined)
            return null;

        const pct = Math.max(0, Math.min(100, Math.round((rssi + 60) / 60 * 100)));
        let icon, label;
        if (rssi >= -10) {
            icon = "network_wifi";        label = "excellent";
        } else if (rssi >= -20) {
            icon = "network_wifi_3_bar";  label = "good";
        } else if (rssi >= -30) {
            icon = "network_wifi_2_bar";  label = "fair";
        } else if (rssi >= -45) {
            icon = "network_wifi_1_bar";  label = "weak";
        } else {
            icon = "signal_wifi_bad";     label = "very weak";
        }
        return { rssi: rssi, pct: pct, icon: icon, label: label };
    }

    function coreRows(dev) {
        const rows = [
            { label: "Battery", value: statusFor(dev), icon: "" },
            { label: "MAC Address", value: dev.address || "unknown", icon: "" }
        ];
        const sig = signalFor(dev);
        if (sig)
            rows.push({ label: "Signal", value: sig.pct + "%", icon: sig.icon });
        return rows;
    }

    function deviceFor(key) {
        return devices.find(d => keyFor(d) === key) ?? null;
    }

    // There's one popout per plugin, not per pill entry, so each device's click
    // surface swaps the subject rather than opening a second window. Clicking
    // the device already showing is the only thing that closes it; clicking a
    // different one just re-points it, which beats closing and reopening.
    function showDevice(key) {
        if (popoutOpen && selectedKey === key) {
            closePopout();
            return;
        }
        selectedKey = key;
        if (!popoutOpen)
            triggerPopout();
    }

    // The pill is instantiated once per bar, so three monitors means three of
    // these racing to notify. pluginService state is shared; a short window
    // through it collapses them into one.
    function notifyLow(dev) {
        if (!notifyCritical)
            return;
        const key = keyFor(dev);
        const now = Date.now();
        if (pluginService && pluginId) {
            const saved = pluginService.loadPluginState(pluginId, "lastCriticalNotice", {});
            const map = (saved && typeof saved === "object") ? saved : {};
            if (now - Number(map[key] ?? 0) < 60000)
                return;
            map[key] = now;
            pluginService.savePluginState(pluginId, "lastCriticalNotice", map);
        }
        notifyProc.command = ["notify-send", "-u", "critical", "-a", "Peripheral Battery",
                              "-i", "battery-caution",
                              dev.name + " battery critical", dev.level + "% remaining"];
        notifyProc.running = true;
    }

    function updateVisibility() {
        setVisibilityOverride(hasDevices || !hideWhenEmpty);
    }

    onHasDevicesChanged: updateVisibility()
    Component.onCompleted: updateVisibility()

    onDevicesChanged: {
        // The first tick fires before the sysfs probe has answered, so the
        // opening poll only ever sees the BlueZ half. Re-poll as devices land.
        pollRssi();

        const next = {};
        for (const dev of devices) {
            const key = keyFor(dev);
            const low = !dev.charging && dev.level <= criticalThreshold;
            if (!low)
                continue;
            next[key] = true;
            if (!_critical[key])   // only on the way down
                notifyLow(dev);
        }
        _critical = next;
    }

    Process {
        id: notifyProc
    }

    Process {
        id: probeProc
        command: ["sh", "-c", root.probe]
        stdout: StdioCollector {
            onStreamFinished: root.sysfsDevices = root.parseSysfs(text)
        }
    }

    Process {
        id: rssiProc
        stdout: StdioCollector {
            onStreamFinished: root.applyRssi(text)
        }
    }

    function pollRssi() {
        const addrs = devices.map(d => d.address).filter(a => a);
        if (!addrs.length || rssiProc.running)
            return;
        rssiProc.command = ["sh", "-c",
            'for a in "$@"; do ' +
            'r=$(hcitool rssi "$a" 2>/dev/null | sed -n "s/.*: *//p"); ' +
            '[ -n "$r" ] && echo "$a $r"; done',
            "peripheralBattery"].concat(addrs);
        rssiProc.running = true;
    }

    // They're batteries, not stopwatches. The BlueZ half updates on its own.
    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            probeProc.running = true;
            root.pollRssi();
        }
    }

    // A reading taken a minute ago is no use the moment you go looking at it.
    onPopoutOpenChanged: if (popoutOpen) pollRssi()

    // DankTooltip was the wrong tool for this: it's pinned to a single elided
    // line, so a label/value table was never going to fit.
    popoutWidth: 440

    popoutContent: Component {
        Column {
            id: card

            readonly property var dev: root.deviceFor(root.selectedKey) ?? root.devices[0] ?? null
            readonly property real innerWidth: width - Theme.spacingL * 2

            width: parent.width
            padding: Theme.spacingL
            spacing: Theme.spacingS

            // PluginPopout assigns this on load; it's our only handle on whether
            // the popout is actually up. See the note on root.popoutRef.
            property var parentPopout: null
            onParentPopoutChanged: root.popoutRef = parentPopout

            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: card.dev ? root.iconFor(card.dev) : "battery_unknown"
                    size: root.popoutFontSize * 1.2
                    color: card.dev ? root.colorFor(card.dev) : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: card.dev ? card.dev.name : "No device"
                    font.pixelSize: root.popoutFontSize * 1.1
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Repeater {
                model: card.dev ? root.coreRows(card.dev) : []

                delegate: Item {
                    id: line

                    required property var modelData

                    width: card.innerWidth
                    implicitHeight: Math.max(keyText.implicitHeight, valRow.implicitHeight)

                    StyledText {
                        id: keyText

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: line.modelData.label + ":"
                        font.pixelSize: root.popoutFontSize
                        color: Theme.surfaceVariantText
                    }

                    Row {
                        id: valRow

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DankIcon {
                            visible: line.modelData.icon !== ""
                            name: line.modelData.icon || "circle"
                            size: root.popoutFontSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: line.modelData.value
                            font.pixelSize: root.popoutFontSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle {
                visible: (card.dev?.details?.length ?? 0) > 0
                width: card.innerWidth
                height: 1
                color: Theme.surfaceVariantText
                opacity: 0.25
            }

            // The small print. Whatever the device's source happens to know --
            // BlueZ and sysfs each volunteer a different half -- plus the raw
            // radio figure behind the percentage above.
            Repeater {
                model: {
                    const rows = (card.dev?.details ?? []).slice();
                    const sig = card.dev ? root.signalFor(card.dev) : null;
                    if (sig)
                        rows.unshift({ label: "Signal (RSSI)",
                                       value: sig.rssi + " (" + sig.label + ")" });
                    return rows;
                }

                delegate: Item {
                    id: detail

                    required property var modelData

                    width: card.innerWidth
                    implicitHeight: Math.max(detailKey.implicitHeight, detailVal.implicitHeight)

                    StyledText {
                        id: detailKey

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: detail.modelData.label + ":"
                        font.pixelSize: root.detailFontSize
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        id: detailVal

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: detailKey.right
                        anchors.leftMargin: Theme.spacingM
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideMiddle
                        text: detail.modelData.value
                        font.pixelSize: root.detailFontSize
                        color: Theme.surfaceText
                    }
                }
            }
        }
    }

    // BatteryMeter is the shape I want but it reads BatteryService directly and
    // takes no level, so it only ever draws the system battery. This is that
    // idea, shrunk, with the charge passed in. Upright by default: width is the
    // scarce axis on a top bar, height is free.
    component Meter: Item {
        id: meter

        property int level: 0
        property color tint: Theme.surfaceText
        property real unit: 14
        property bool upright: true

        readonly property real pct: Math.max(0, Math.min(100, level)) / 100
        readonly property int thick: Math.max(6, Math.round(unit * 0.52))
        readonly property int span: Math.max(10, Math.round(unit * 0.82))
        readonly property int cap: Math.max(1, Math.round(thick / 5))
        readonly property int nub: Math.max(2, Math.round(thick * 0.45))
        readonly property int bw: Math.max(1, Math.round(thick / 8))
        readonly property int inset: bw + 1

        implicitWidth: upright ? thick : span + cap
        implicitHeight: upright ? span + cap : thick

        Rectangle {
            id: body

            x: 0
            y: meter.upright ? meter.cap : 0
            width: meter.upright ? meter.thick : meter.span
            height: meter.upright ? meter.span : meter.thick
            radius: Math.max(1, Math.round(meter.thick / 4))
            color: "transparent"
            border.width: meter.bw
            border.color: meter.tint

            // Drains downward when upright, leftward when not.
            Rectangle {
                x: meter.inset
                y: meter.upright ? parent.height - meter.inset - height : meter.inset
                width: meter.upright ? parent.width - 2 * meter.inset
                                     : Math.max(0, (parent.width - 2 * meter.inset) * meter.pct)
                height: meter.upright ? Math.max(0, (parent.height - 2 * meter.inset) * meter.pct)
                                      : parent.height - 2 * meter.inset
                radius: Math.max(1, Math.round(Math.min(width, height) / 3))
                color: meter.tint
            }
        }

        Rectangle {
            x: meter.upright ? Math.round((meter.thick - width) / 2) : body.width
            y: meter.upright ? 0 : Math.round((meter.thick - height) / 2)
            width: meter.upright ? meter.nub : meter.cap
            height: meter.upright ? meter.cap : meter.nub
            radius: Math.max(1, Math.round(Math.min(width, height) / 2))
            color: meter.tint
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            Repeater {
                model: root.devices

                // An Item, not a Row: the click surface has to fill this, and a
                // child that fills its parent inside a positioner makes the
                // parent's size depend on the child's and vice versa. Qt breaks
                // that cycle by collapsing the lot to 0x0.
                delegate: Item {
                    id: entry

                    required property var modelData
                    required property int index

                    implicitWidth: entryRow.implicitWidth
                    implicitHeight: entryRow.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: entryRow

                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: root.iconFor(entry.modelData)
                            size: root.pillIconSize
                            color: root.colorFor(entry.modelData)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            visible: root.showLabels
                            text: entry.modelData.name
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Meter {
                            visible: entry.modelData.level <= root.meterThreshold
                            level: entry.modelData.level
                            tint: root.colorFor(entry.modelData)
                            unit: root.pillIconSize
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Each entry owns its clicks; BasePill's own handler never
                    // sees them, so the plugin-wide toggle stays out of it.
                    //
                    // Deliberately bigger than what it sits on. The Item's size
                    // comes from entryRow, and a MouseArea isn't in a positioner
                    // here, so overhanging costs the layout nothing. Inward it
                    // takes half the row gap, so neighbours tile and no sliver
                    // between icons falls through to the pill; outward it eats
                    // the pill's own padding. Vertically it fills the widget.
                    MouseArea {
                        readonly property real slopL: entry.index === 0 ? root.hitSlopOut : root.hitSlopIn
                        readonly property real slopR: entry.index === root.devices.length - 1
                                                      ? root.hitSlopOut : root.hitSlopIn

                        x: -slopL
                        width: entry.width + slopL + slopR
                        height: Math.max(entry.height, root.widgetThickness)
                        y: (entry.height - height) / 2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showDevice(root.keyFor(entry.modelData))
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            Repeater {
                model: root.devices

                delegate: Column {
                    id: ventry

                    required property var modelData

                    spacing: 0
                    anchors.horizontalCenter: parent.horizontalCenter

                    DankIcon {
                        name: root.iconFor(ventry.modelData)
                        size: root.pillIconSize
                        color: root.colorFor(ventry.modelData)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Meter {
                        visible: ventry.modelData.level <= root.meterThreshold
                        level: ventry.modelData.level
                        tint: root.colorFor(ventry.modelData)
                        unit: root.pillIconSize
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
