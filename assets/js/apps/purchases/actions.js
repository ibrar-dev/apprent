import axios from "axios";
import store from "./store";

const actions = {
  fetchPurchases() {
    axios.get("/api/reward_purchases").then((r) => {
      store.dispatch({
        type: "SET_PURCHASES",
        purchases: r.data.purchases,
      });
    });
  },

  updatePurchase(purchase) {
    const promise = axios.patch('/api/reward_purchases/' + purchase.id, {purchase});
    promise.then(actions.fetchPurchases);
    return promise;
  },

  deletePurchase(purchase) {
    const promise = axios.delete('/api/reward_purchases/' + purchase.id);
    promise.then(actions.fetchPurchases);
    return promise;
  },
};

export default actions;