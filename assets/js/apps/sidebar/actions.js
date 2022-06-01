import React from "react";
import store from "./store";
import {getCookie, setCookie} from "../../utils/cookies";
import {permissions} from "./links";
import Channel from "./channel";
import snackbar from "../../components/snackbar";

const roleKey = "adminRole";

const classToDisplay = (flag) => {
  if (flag >= 4) return "error";
  if (flag === 3) return "warn";
  if (flag < 3) return "success";
};

const actions = {
  setRole(role) {
    setCookie(roleKey, role);
    store.dispatch({
      type: "SET_ROLE",
      role,
    });
  },
  initializeChannel() {
    actions.channel = new Channel();
    actions.channel.register("UPDATE_TOTAL", actions.fetchTotal());
  },
  newAlert({alert}) {
    snackbar({
      message: (<div>
        <p>
          New Alert From:
          {alert.sender}
        </p>
        <p>{alert.note}</p>
      </div>),
      args: {type: classToDisplay(alert.flag)},
    });
  },
  updateTotal({unread: total}) {
    store.dispatch({
      type: "SET_UNREAD",
      unread: total,
    });
  },
  fetchTotal() {
    actions.channel.socket.channels[0].push("UPDATE_TOTAL", {});
  },
};

const role = getCookie(roleKey);
role && permissions.some((r) => r === role) && actions.setRole(role);

export default actions;
