/* =============== 🧠 2. extension.js =============== */
const { St, Gio, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Soup = imports.gi.Soup;

let jajaButton;

class JajaN8nCommand extends PanelMenu.Button {
  _init() {
    super._init(0.0, "JAJA N8N Command", false);

    // Иконка расширения
    const icon = new St.Icon({
      icon_name: 'jaja-symbolic',
      style_class: 'system-status-icon',
    });
    this.add_child(icon);

    // Поле ввода команды
    this.inputItem = new St.Entry({
      name: 'jajaCommandEntry',
      style_class: 'jaja-entry',
      hint_text: 'Введите команду для JAJA...',
      x_expand: true,
      can_focus: true,
    });

    let entryBox = new PopupMenu.PopupBaseMenuItem({
      reactive: false,
      can_focus: false,
    });
    entryBox.actor.add(this.inputItem);
    this.menu.addMenuItem(entryBox);

    // Кнопка отправки команды
    let sendButton = new PopupMenu.PopupMenuItem('📤 Отправить');
    sendButton.connect('activate', () => this._sendCommand());
    this.menu.addMenuItem(sendButton);
  }

  _sendCommand() {
    const commandText = this.inputItem.get_text();
    if (!commandText) return;

    // Webhook URL (локальный)
    const url = 'http://localhost:5678/webhook/command-input';

    // HTTP POST
    let session = new Soup.Session();
    let message = Soup.Message.new('POST', url);
    message.set_request('application/json', Soup.MemoryUse.COPY,
      JSON.stringify({ command: commandText })
    );

    session.queue_message(message, (session, response) => {
      if (response.status_code === 200) {
        Main.notify('JAJA Agent', 'Команда отправлена! ✅');
      } else {
        Main.notifyError('JAJA Agent', 'Ошибка отправки команды');
      }
    });
  }
}

function init() {}

function enable() {
  jajaButton = new JajaN8nCommand();
  Main.panel.addToStatusArea('jaja-n8n-command', jajaButton);
}

function disable() {
  jajaButton.destroy();
}
