const { St, Gio, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Soup = imports.gi.Soup;
const Lang = imports.lang;

let JajaAgentExtension;

class JajaAgentButton extends PanelMenu.Button {
    constructor() {
        super(0.0, "Jaja N8N Command");

        this.box = new St.BoxLayout({ style_class: 'panel-status-menu-box' });
        this.entry = new St.Entry({ name: 'JajaCommandEntry', hint_text: 'Введите команду для Jaja Agent', track_hover: true });
        this.sendButton = new St.Button({ label: "▶", style_class: 'system-menu-action' });

        this.box.add_child(this.entry);
        this.box.add_child(this.sendButton);
        this.actor.add_child(this.box);

        this.sendButton.connect('clicked', () => {
            const text = this.entry.get_text().trim();
            if (text.length > 0) {
                this._sendCommandToWebhook(text);
                this.entry.set_text('');
            }
        });
    }

    _sendCommandToWebhook(command) {
        let session = new Soup.Session();
        let message = Soup.Message.new('POST', 'http://localhost:5678/webhook/jaja-command');

        message.set_request('application/json', Soup.MemoryUse.COPY,
            JSON.stringify({ command: command }));

        session.queue_message(message, (session, message) => {
            if (message.status_code === 200) {
                log("✅ Команда успешно отправлена в N8N: " + command);
            } else {
                log("❌ Ошибка при отправке команды: " + message.status_code);
            }
        });
    }
}

function init() {}

function enable() {
    JajaAgentExtension = new JajaAgentButton();
    Main.panel.addToStatusArea('JajaN8NCommand', JajaAgentExtension);
}

function disable() {
    if (JajaAgentExtension) {
        JajaAgentExtension.destroy();
        JajaAgentExtension = null;
    }
}
