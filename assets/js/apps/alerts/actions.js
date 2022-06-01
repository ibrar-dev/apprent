import store from './store';
import Channel from './channel';

const actions = {
  initializeChannel() {
    actions.channel = new Channel();
    actions.channel.register('FETCH_ALERTS', actions.fetchAlerts());
  },
  setAlerts({unread: alerts}) {
    store.dispatch({
      type: 'SET_ALERTS',
      alerts: alerts
    })
  },
  fetchEmployees() {
    actions.channel.socket.channels[0].push('FETCH_EMPLOYEES', {})
  },
  updateAlerts() {
    actions.fetchAlerts();
    actions.channel.socket.channels[0].push('UPDATE_TOTAL', {})
  },
  newAlert(alert) {
    actions.updateAlerts()
  },
  fetchAlerts() {
    actions.channel.socket.channels[0].push("FETCH_ALERTS", {})
  },
  updateAlert(alert) {
    alert.read ? actions.unreadAlert(alert.id) : actions.readAlert(alert.id);
  },
  readAlert(alertId) {
    actions.channel.socket.channels[0].push("READ_ALERT", alertId)
  },
  unreadAlert(alertId) {
    actions.channel.socket.channels[0].push("UNREAD_ALERT", alertId)
  },
  deleteAlert(alertId) {
    actions.channel.socket.channels[0].push("DELETE_ALERT", alertId);
    actions.updateAlerts();
  }
};

export default actions;