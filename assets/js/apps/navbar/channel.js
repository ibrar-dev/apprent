import actions from './actions';
import Socket from '../../utils/adminSocket';

class Channel {
  constructor() {
    this.listeners = {};
    this.socket = Socket;
    this.channel = this.socket.channel(`alerts:${window.admin_id}`, {});
    this.channel.join()
      .receive('ok', this.setListeners.bind(this))
      .receive('error', () => console.log('could not connect to alerts channel'));
  }

  register(message, callback) {
    if (!this.listeners[message]) this.listeners[message] = [];
    this.listeners[message].push(callback);
  }

  broadcast(message, content) {
    switch (message) {
      case 'alert':
        return actions.newAlert(content);
      case 'total':
        return actions.updateTotal(content);
      default:
        return null;
    }
    // this.listeners[message].forEach(listener => listener(content));
    // if (message === "alert") return actions.newAlert(content);
  }

  setListeners() {
    console.log("Joined alert channel from sidebar successfully");
    this.channel.on('NEW_ALERT', this.broadcast.bind(this, 'alert'));
    this.channel.on('UNREAD_ALERTS', this.broadcast.bind(this, 'total'));
  }
}

export default Channel;