// 📄 extension.js - основной код расширения
const { St, Gio, GLib, Soup } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Lang = imports.lang;
const ExtensionUtils = imports.misc.extensionUtils;

let panelButton;

class JajaN8NExtension extends PanelMenu.Button {
  _init() {
    super._init(0.0, "JAJA N8N Command");

    // Загрузка иконки
    let icon = new St.Icon({
      gicon: Gio.icon_new_for_string(Me.path + "/icons/Jaja.png"),
      style_class: "system-status-icon"
    });
    this.add_child(icon);

    // Меню ввода
    let item = new PopupMenu.PopupBaseMenuItem();
    let entry = new St.Entry({
      style_class: "popup-entry-box",
      can_focus: true,
      hint_text: "Введите команду для JAJA N8N..."
    });
    item.actor.add(entry);
    this.menu.addMenuItem(item);

    entry.clutter_text.connect("activate", () => {
      let command = entry.get_text();
      this._sendCommand(command);
      entry.set_text("");
      this.menu.close();
    });
  }

  _sendCommand(command) {
    // Отправка команды через HTTP POST
    let session = new Soup.Session();
    let message = Soup.Message.new("POST", "http://localhost:5678/webhook/command-input");
    message.set_request("application/json", Soup.MemoryUse.COPY,
      JSON.stringify({ command: command }));
    session.send_message(message);
  }
}

function init() {
  Me = ExtensionUtils.getCurrentExtension();
}

function enable() {
  panelButton = new JajaN8NExtension();
  Main.panel.addToStatusArea("jaja-n8n-command", panelButton);
}

function disable() {
  panelButton.destroy();
}
