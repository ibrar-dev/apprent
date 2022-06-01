import {Socket} from 'phoenix';

const socket = new Socket('/ws/users', {});
socket.connect();
let channel = socket.channel(`users/${window.current_user_id}`, {})
channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

export default socket;