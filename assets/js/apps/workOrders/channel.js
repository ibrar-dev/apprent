import Socket from '../../utils/adminSocket';

class Channel {
  constructor() {
    this.listeners = {};
    this.socket = Socket;
    this.channel = this.socket.channel('tech_admin', {});
    this.channel.join()
      .receive('ok', this.setListeners.bind(this))
      .receive('error', () => console.log('could not connect to admin channel'));
  }

  register(message, callback) {
    if (!this.listeners[message]) this.listeners[message] = [];
    this.listeners[message].push(callback);
  }

  broadcast(message, content) {
    this.listeners[message].forEach(listener => listener(content));
  }

  setListeners() {
    console.log("Joined channel successfully");
    this.channel.on('COORDINATES', this.broadcast.bind(this, 'coordinates'));
    this.channel.on('ASSIGNMENT', this.broadcast.bind(this, 'assignment'));
    this.channel.on('REJECT', this.broadcast.bind(this, 'reject'));
    this.channel.on('CHAT', this.broadcast.bind(this, 'chat'));
    this.channel.on('presence_diff', this.broadcast.bind(this, 'presence_diff'));
  }
}

export default Channel;