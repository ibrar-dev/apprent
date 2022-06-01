import {Socket} from 'phoenix';

const socket = new Socket('/ws/user', {params: {user_token: window.user_token}});
socket.connect();

export default socket;