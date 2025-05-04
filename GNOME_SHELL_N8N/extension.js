/*
  Расширение добавляет иконку JAJA в топбар GNOME,
  по клику открывается поле ввода, куда можно ввести команду.
  Команда отправляется POST-запросом на локальный n8n webhook.
*/

const { St, GLib, Soup } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

let panelButton;

class JAJACommandButton extends PanelMenu.Button {
  constructor() {
    super(0.0, 'JAJA N8N Command');

    const icon = new St.Icon({
      gicon: Gio.icon_new_for_string(`${Me.path}/icons/icon.png`),
      style_class: 'system-status-icon',
    });

    this.add_child(icon);

    const entry = new St.Entry({
      hint_text: 'Введите команду для JAJA...',
      track_hover: true,
      can_focus: true,
      style_class: 'jaja-entry'
    });

    const menuItem = new PopupMenu.PopupBaseMenuItem({ activate: false });
    menuItem.actor.add(entry);
    this.menu.addMenuItem(menuItem);

    entry.clutter_text.connect('activate', () => {
      const text = entry.get_text();
      if (text.length > 0) {
        this._sendCommandToWebhook(text);
        entry.set_text('');
      }
    });
  }

  _sendCommandToWebhook(command) {
    const session = new Soup.Session();
    const message = Soup.Message.new('POST', 'http://localhost:5678/webhook/command-input');
    const body = JSON.stringify({ command });
    message.set_request('application/json', Soup.MemoryUse.COPY, body);
    session.queue_message(message, () => {});
  }
}

function init() {}

function enable() {
  panelButton = new JAJACommandButton();
  Main.panel.addToStatusArea('jaja-n8n-command', panelButton);
}

function disable() {
  panelButton.destroy();
  panelButton = null;
}
