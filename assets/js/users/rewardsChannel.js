import Socket from './userSocket';

class Channel {
  constructor() {
    this.listeners = {};
    this.socket = Socket;
    this.channel = this.socket.channel(`rewards:${window.current_user_id}`)
    this.channel.join()
        .receive('ok', this.setListeners.bind(this))
        .receive('error', () => console.log('could not connect to rewards channel'));
  }

  register(message, callback) {
    if (!this.listeners[message]) this.listeners[message] = [];
    this.listeners[message].push(callback);
  }

  broadcast(message, content) {
    switch (message) {
      default:
        this.searchList(content.body)
        // console.group('Rewards Channel');
        // console.log(message);
        // console.log(content);
        // console.groupEnd();
        // case 'alert':
        //   return actions.newAlert(content);
        // case 'total':
        //   return actions.updateTotal(content);
        // default:
        //   return null;
    }
    // this.listeners[message].forEach(listener => listener(content));
    // if (message === "alert") return actions.newAlert(content);
  }

  searchList(params){
    var points = sessionStorage.userPoints
    var myNode = $('#rewardSearchList')[0];
    while (myNode.firstChild) {
      myNode.removeChild(myNode.firstChild);
    }
    for (var i = 0; i < 5; i++) {
      var reward = document.createElement("LI");
      var rewardName = document.createElement("H6");
      rewardName.style = "font-size:12px; margin-bottom:0px; color: #3a3c42;"
      rewardName.appendChild(document.createTextNode(params[i].name));
      var rewardPoints = document.createElement("H6");
      rewardPoints.style = "font-size:12px; margin-bottom:0px; color: #22994c;"
      rewardPoints.appendChild(document.createTextNode(params[i].points));
      var div = document.createElement("DIV");
      div.className = "col"
      div.appendChild(rewardName);
      div.appendChild(rewardPoints);
      reward.className = points < params[i].points ? "disabledPrize list-group-item d-flex align-items-center" : "list-group-item d-flex align-items-center";
      reward.style = points < params[i].points ? "border:none; opacity:.5" : "border:none; cursor: pointer";
      reward.onclick = function () {
        if (!this.className.includes("disabledPrize")) $('#prizeModal').modal('toggle')
      };
      var icon = document.createElement("DIV");
      icon.className = "circle-icon d-flex align-items-center";
      icon.style = "margin-right:12px;"
      var img = document.createElement("IMG");
      img.setAttribute('src', params[i].icon);
      img.className = "w-100";
      icon.appendChild(img);       // Create a text node
      reward.appendChild(icon);
      reward.appendChild(div);
      $('#rewardSearchList')[0].appendChild(reward);
    }
  }

  setListeners() {
    console.log("Joined rewards channel successfully");
    this.channel.on('SHOW_REWARDS', this.broadcast.bind(this, 'show'));
    this.channel.on('SEARCH_REWARDS', this.broadcast.bind(this, 'search'));
  }
}

export default Channel;