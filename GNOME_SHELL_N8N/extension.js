import { St, Clutter, Gio } from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as ExtensionUtils from 'resource:///org/gnome/shell/extensions/extensionUtils.js';

export default class JajaN8nCommandExtension {
  constructor() {
    this._indicator = null;
  }

  enable() {
    this._indicator = new PanelMenu.Button(0.0, 'Jaja n8n Command');

    const box = new St.BoxLayout({ style_class: 'panel-status-menu-box' });
    this._indicator.add_child(box);

    const entry = new St.Entry({
      style_class: 'jaja-entry',
      hint_text: 'Введите команду...',
      track_hover: true,
      can_focus: true
    });

    entry.clutter_text.connect('activate', () => {
      const command = entry.get_text();
      this._sendCommand(command);
      entry.set_text('');
    });

    box.add_child(entry);
    Main.panel.addToStatusArea('jaja-n8n-command', this._indicator);
  }

  disable() {
    if (this._indicator) {
      this._indicator.destroy();
      this._indicator = null;
    }
  }

  _sendCommand(command) {
    const webhookUrl = 'https://n8n.example.com/webhook/jaja';
    const session = new Soup.Session();

    const message = Soup.Message.new('POST', webhookUrl);
    message.set_request('application/json', Soup.MemoryUse.COPY, JSON.stringify({ command }));

    session.queue_message(message, (session, response) => {
      if (response.status_code !== 200) {
        log(`Ошибка отправки команды: ${response.status_code}`);
      }
    });
  }
}
