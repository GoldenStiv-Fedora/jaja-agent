const { St, Gio, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

let jajaEntry;

class JajaN8NCommand extends PanelMenu.Button {
    constructor() {
        super(0.0, 'Jaja N8N Command');

        const icon = new St.Icon({
            icon_name: 'system-run-symbolic',
            style_class: 'system-status-icon',
        });

        this.actor.add_child(icon);

        const entry = new St.Entry({
            hint_text: 'Введите команду для Jaja',
            track_hover: true,
            can_focus: true,
        });

        entry.clutter_text.connect('activate', () => {
            const text = entry.get_text();
            this._sendCommandToN8N(text);
            entry.set_text('');
        });

        const menuItem = new PopupMenu.PopupBaseMenuItem({ reactive: false });
        menuItem.actor.add_child(entry);
        this.menu.addMenuItem(menuItem);
    }

    _sendCommandToN8N(command) {
        const url = 'http://localhost:5678/webhook/jaja-command'; // <== ЗДЕСЬ ВАШ ВЕБХУК
        const payload = JSON.stringify({ input: command });

        try {
            Gio._http_post = Gio.File.new_for_path('/usr/bin/curl');
            if (Gio._http_post.query_exists(null)) {
                GLib.spawn_command_line_async(`curl -X POST -H "Content-Type: application/json" -d '${payload}' "${url}"`);
            }
        } catch (e) {
            log(`Ошибка отправки команды: ${e}`);
        }
    }
}

function init() {}

function enable() {
    jajaEntry = new JajaN8NCommand();
    Main.panel.addToStatusArea('JajaN8NCommand', jajaEntry);
}

function disable() {
    if (jajaEntry) {
        jajaEntry.destroy();
        jajaEntry = null;
    }
}
