import {Socket} from 'phoenix';
import token from './token';

const socket = new Socket('/ws/admin', {params: {token}});
socket.connect();

export default socket;