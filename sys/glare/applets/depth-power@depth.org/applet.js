const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;

class DepthPowerApplet extends Applet.TextIconApplet {
    constructor(orientation, panel_height, instance_id) {
        super(orientation, panel_height, instance_id);
        this.set_applet_icon_symbolic_name("battery-full-charging-symbolic");
        this.set_applet_label("100%");
        this.set_applet_tooltip("Depth Hinux Power: 100% (AC Online)");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this.titleItem = new PopupMenu.PopupMenuItem("Depth Hinux Battery & Power Driver", { reactive: false });
        this.menu.addMenuItem(this.titleItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this.chargeItem = new PopupMenu.PopupMenuItem("Battery Level: 100%", { reactive: false });
        this.menu.addMenuItem(this.chargeItem);

        this.stateItem = new PopupMenu.PopupMenuItem("Power State: AC Connected (Full)", { reactive: false });
        this.menu.addMenuItem(this.stateItem);

        this.healthItem = new PopupMenu.PopupMenuItem("Battery Health: Optimal (100%)", { reactive: false });
        this.menu.addMenuItem(this.healthItem);

        this.profileItem = new PopupMenu.PopupMenuItem("Profile: Depth High Performance", { reactive: false });
        this.menu.addMenuItem(this.profileItem);

        this._updateLoop();
    }

    on_applet_clicked(event) {
        this.menu.toggle();
    }

    _readStatus() {
        let path = "/run/hinux/power.stat";
        let data = {
            percent: "100",
            status: "Full",
            ac: "Online",
            health: "Good",
            source: "AC Power"
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
                            if (k === "PERCENT") data.percent = v;
                            if (k === "STATUS") data.status = v;
                            if (k === "AC") data.ac = v;
                            if (k === "HEALTH") data.health = v;
                            if (k === "SOURCE") data.source = v;
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
        let pct = parseInt(info.percent) || 100;

        if (info.ac === "Online") {
            this.set_applet_icon_symbolic_name("battery-full-charging-symbolic");
            this.set_applet_label(pct + "%");
            this.set_applet_tooltip("Depth Power: " + pct + "% (AC Connected)");
            this.stateItem.label.text = "Power State: AC Connected (" + info.status + ")";
        } else {
            if (pct > 75) {
                this.set_applet_icon_symbolic_name("battery-full-symbolic");
            } else if (pct > 40) {
                this.set_applet_icon_symbolic_name("battery-good-symbolic");
            } else if (pct > 15) {
                this.set_applet_icon_symbolic_name("battery-low-symbolic");
            } else {
                this.set_applet_icon_symbolic_name("battery-caution-symbolic");
            }
            this.set_applet_label(pct + "%");
            this.set_applet_tooltip("Depth Battery: " + pct + "% (" + info.status + ")");
            this.stateItem.label.text = "Power State: Battery (" + info.status + ")";
        }

        this.chargeItem.label.text = "Battery Level: " + pct + "%";
        this.healthItem.label.text = "Power Source: " + info.source;

        Mainloop.timeout_add_seconds(2, () => {
            this._updateLoop();
            return false;
        });
    }
}

function main(metadata, orientation, panel_height, instance_id) {
    return new DepthPowerApplet(orientation, panel_height, instance_id);
}
