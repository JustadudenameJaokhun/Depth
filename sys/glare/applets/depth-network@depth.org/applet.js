const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;

class DepthNetworkApplet extends Applet.TextIconApplet {
    constructor(orientation, panel_height, instance_id) {
        super(orientation, panel_height, instance_id);
        this.set_applet_icon_symbolic_name("network-offline-symbolic");
        this.set_applet_label("");
        this.set_applet_tooltip("Depth Network: Scanning hardware...");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this.titleItem = new PopupMenu.PopupMenuItem("Depth Hinux Network Driver", { reactive: false });
        this.menu.addMenuItem(this.titleItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this.ifaceItem = new PopupMenu.PopupMenuItem("Interface: Scanning...", { reactive: false });
        this.menu.addMenuItem(this.ifaceItem);

        this.statusItem = new PopupMenu.PopupMenuItem("Status: Disconnected", { reactive: false });
        this.menu.addMenuItem(this.statusItem);

        this.ipItem = new PopupMenu.PopupMenuItem("IPv4: Not assigned", { reactive: false });
        this.menu.addMenuItem(this.ipItem);

        this.speedItem = new PopupMenu.PopupMenuItem("Link Speed: Offline", { reactive: false });
        this.menu.addMenuItem(this.speedItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this.termItem = new PopupMenu.PopupIconMenuItem("Open Network Terminal", "utilities-terminal", St.IconType.SYMBOLIC);
        this.termItem.connect("activate", () => {
            Util.spawn(["gnome-terminal", "--", "network"]);
        });
        this.menu.addMenuItem(this.termItem);

        this._updateLoop();
    }

    on_applet_clicked(event) {
        this.menu.toggle();
    }

    _readStatus() {
        let path = "/run/hinux/net.stat";
        let data = {
            iface: "none",
            status: "disconnected",
            type: "none",
            ip: "none",
            speed: "0",
            carrier: "0"
        };
        try {
            if (GLib.file_test(path, GLib.FileTest.EXISTS)) {
                let [ok, content] = GLib.file_get_contents(path);
                if (ok) {
                    let lines = ("" + content).split("\n");
                    for (let line of lines) {
                        let parts = line.split("=");
                        if (parts.length === 2) {
                            let k = parts[0].trim();
                            let v = parts[1].trim();
                            if (k === "INTERFACE") data.iface = v;
                            if (k === "STATUS") data.status = v;
                            if (k === "TYPE") data.type = v;
                            if (k === "IP") data.ip = v;
                            if (k === "SPEED") data.speed = v;
                            if (k === "CARRIER") data.carrier = v;
                        }
                    }
                }
            }
        } catch (e) {
        }
        return data;
    }

    _updateLoop() {
        let info = this._readStatus();
        let isOnline = (info.carrier === "1" && info.status === "connected" && info.ip !== "none" && info.ip !== "");
        let isWireless = (info.type === "wireless" || info.iface.startsWith("wl"));

        if (isOnline) {
            let iconName = isWireless ? "network-wireless-symbolic" : "network-wired-symbolic";
            this.set_applet_icon_symbolic_name(iconName);
            let medium = isWireless ? "Wi-Fi" : "Ethernet";
            this.set_applet_tooltip("Depth Network: Connected via " + medium + " (" + info.iface + " - " + info.ip + ")");
            this.statusItem.label.text = "Status: Connected (Online)";
            this.ifaceItem.label.text = "Interface: " + info.iface + " (" + medium + ")";
            this.ipItem.label.text = "IPv4: " + info.ip;
            this.speedItem.label.text = "Link Speed: " + (info.speed !== "0" ? info.speed : "Active");
        } else {
            this.set_applet_icon_symbolic_name("network-offline-symbolic");
            this.set_applet_tooltip("Depth Network: Disconnected");
            this.statusItem.label.text = "Status: Disconnected";
            this.ifaceItem.label.text = "Interface: " + (info.iface !== "none" ? info.iface : "No device");
            this.ipItem.label.text = "IPv4: Not assigned";
            this.speedItem.label.text = "Link Speed: Offline";
        }

        Mainloop.timeout_add_seconds(2, () => {
            this._updateLoop();
            return false;
        });
    }
}

function main(metadata, orientation, panel_height, instance_id) {
    return new DepthNetworkApplet(orientation, panel_height, instance_id);
}
