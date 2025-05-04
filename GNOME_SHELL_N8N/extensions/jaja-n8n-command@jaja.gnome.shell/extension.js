// Основной файл расширения

const { St, Clutter, Gio, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const ExtensionUtils = imports.misc.extensionUtils;

class JajaExtension extends PanelMenu.Button {
  constructor() {
    super(0.0, 'JAJA N8N Agent');

    // Иконка в панели GNOME
    const iconPath = ExtensionUtils.getCurrentExtension().path + '/icons/Jaja.png';
    const gicon = Gio.icon_new_for_string(iconPath);
    this.icon = new St.Icon({ gicon, icon_size: 24 });
    this.add_child(this.icon);

    // Всплывающее окно
    const box = new St.BoxLayout({ vertical: true, style_class: 'jaja-n8n-box' });
    this.entry = new St.Entry({ hint_text: 'Введите команду...', style_class: 'jaja-n8n-entry' });
    const sendButton = new St.Button({ label: 'Отправить', style_class: 'jaja-n8n-button' });

    sendButton.connect('clicked', () => this._sendCommand());

    box.add_child(this.entry);
    box.add_child(sendButton);

    const menuItem = new PopupMenu.PopupBaseMenuItem({ activate: false });
    menuItem.actor.add(box);
    this.menu.addMenuItem(menuItem);
  }

  _sendCommand() {
    const command = this.entry.get_text();
    if (!command) return;

    // Отправка команды через curl (можно использовать libsoup, но проще shell)
    GLib.spawn_command_line_async(`curl -X POST http://localhost:5678/webhook/command-input -H "Content-Type: application/json" -d '{"command": "${command}"}'`);

    this.entry.set_text('');
  }

  destroy() {
    super.destroy();
  }
}

let jajaExtension;

function init() {}

function enable() {
  jajaExtension = new JajaExtension();
  Main.panel.addToStatusArea('jaja-n8n-agent', jajaExtension);
}

function disable() {
  if (jajaExtension) {
    jajaExtension.destroy();
    jajaExtension = null;
  }
}
