/* === extension.js === */
const { St, Clutter, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;

let jajaButton;

class JajaAgentMenuButton extends PanelMenu.Button {
    constructor() {
        super(0.0, 'JAJA Agent');

        const icon = new St.Icon({
            icon_name: 'utilities-terminal-symbolic',
            style_class: 'system-status-icon'
        });
        this.add_child(icon);

        const menuItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        const entry = new St.Entry({
            hint_text: 'Введите команду для JAJA Agent...',
            track_hover: true,
            can_focus: true
        });

        entry.clutter_text.connect('key-press-event', (actor, event) => {
            const symbol = event.get_key_symbol();
            if (symbol === Clutter.KEY_Return) {
                const command = entry.get_text();
                this._sendCommandToAgent(command);
                entry.set_text('');
                this.menu.close();
            }
            return Clutter.EVENT_PROPAGATE;
        });

        menuItem.add_child(entry);
        this.menu.addMenuItem(menuItem);
    }

    _sendCommandToAgent(command) {
        const script = `curl -X POST -H 'Content-Type: application/json' -d '{"command": "${command}"}' http://localhost:5678/webhook/command-input`;
        GLib.spawn_command_line_async(`bash -c "${script}"`);
    }
}

function init() {}

function enable() {
    jajaButton = new JajaAgentMenuButton();
    Main.panel.addToStatusArea('jaja-agent-command-entry', jajaButton);
}

function disable() {
    jajaButton.destroy();
} 
