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
      case 'alerts_full':
        return actions.setAlerts(content);
      case 'new_alert':
        return actions.newAlert(content);
      default:
        return null;
    }
    // this.listeners[message].forEach(listener => listener(content));
    // if (message === "alert") return actions.newAlert(content);
  }

  setListeners() {
    console.log("Joined alert channel from alert app successfully");
    this.channel.on('FETCH_ALERTS', this.broadcast.bind(this, 'alerts_full'));
    this.channel.on('NEW_ALERT', this.broadcast.bind(this, 'new_alert'));
  }
}

export default Channel;