/*
  Расширение добавляет иконку JAJA в топбар GNOME,
  по клику открывается поле ввода, куда можно ввести команду.
  Команда отправляется POST-запросом на локальный n8n webhook.
*/

// Основной файл расширения GNOME Shell
const { St, GLib, Gio } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Lang = imports.lang;
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

let jajaButton;

class JajaAgentMenu extends PanelMenu.Button {
  _init() {
    super._init(0.0, 'Jaja N8N Command');

    // Иконка для панели
    let iconPath = Me.path + '/icons/Jaja.png';
    let icon = new St.Icon({
      gicon: Gio.icon_new_for_string(iconPath),
      style_class: 'system-status-icon'
    });
    this.add_child(icon);

    // Поле ввода команды
    this.entry = new St.Entry({
      name: 'JajaEntry',
      hint_text: 'Введите команду для JAJA...',
      track_hover: true,
      can_focus: true
    });

    let entryItem = new PopupMenu.PopupBaseMenuItem({ activate: false });
    entryItem.actor.add_child(this.entry);
    this.menu.addMenuItem(entryItem);

    // Кнопка отправки команды
    let sendItem = new PopupMenu.PopupMenuItem('Отправить команду');
    sendItem.connect('activate', () => {
      let command = this.entry.get_text();
      this._sendToWebhook(command);
    });
    this.menu.addMenuItem(sendItem);
  }

  _sendToWebhook(command) {
    // Отправка POST-запроса на локальный webhook n8n
    GLib.spawn_command_line_async(`curl -X POST http://localhost:5678/webhook/command-input -H "Content-Type: application/json" -d '{"command": "${command}"}'`);
  }
}

function init() {}

function enable() {
  jajaButton = new JajaAgentMenu();
  Main.panel.addToStatusArea('jaja-n8n-command', jajaButton);
}

function disable() {
  if (jajaButton) {
    jajaButton.destroy();
    jajaButton = null;
  }
}
