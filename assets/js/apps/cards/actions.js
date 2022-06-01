import axios from "axios";
import store from "./store";
import snackbar from "../../components/snackbar";
import setLoading from "../../components/loading";

const actions = {
  fetchCards() {
    const properties = store.getState().selectedProperties;
    if (!properties || !properties.length) return;
    setLoading(true);
    axios.get("/api/cards?property_ids=" + properties.join(",")).then(r => {
      setLoading(false);
      this.fetchCardEvents(store.getState().cards.map((c) => c.id));
      this.fetchHiddenCards();
      store.dispatch({
        type: "SET_CARDS",
        cards: r.data,
      });
    });
  },
  fetchHiddenCards() {
    const properties = store.getState().selectedProperties;
    if (!properties || !properties.length) return;
    setLoading(true);
    axios.get("/api/cards?hidden_cards=true&property_ids=" + properties.join(",")).then(r => {
      setLoading(false);
      store.dispatch({
        type: "SET_HIDDEN_CARDS",
        hiddenCards: r.data,
      });
    });
  },
  fetchCardEvents(cardIds) {
    if (cardIds.length > 0) {
      axios.get("/api/cards/last_domain_event?card_ids=" + cardIds.join(",")).then((r) => {
        store.dispatch({
          type: "SET_LAST_DOMAIN_EVENT",
          domainEvent: r.data,
        });
      });
    } else {
      store.dispatch({
        type: "SET_LAST_DOMAIN_EVENT",
        domainEvent: {},
      });
    }
  },
  fetchTechs() {
    axios.get("/api/techs?min=true").then(r => {
      store.dispatch({
        type: "SET_TECHS",
        techs: r.data
      })
    })
  },

  fetchVendors() {
    axios.get("/api/vendors").then(r => {
      store.dispatch({
          type: "SET_VENDORS",
          vendors: r.data
      })
    })
  },

  fetchVendorCategories() {
    axios.get("/api/vendor_categories").then(r => {
      store.dispatch({
          type: "SET_VENDOR_CATEGORIES",
          categories: r.data
      })
    })
  },

  fetchProperties() {
    const promise = axios.get("/api/properties?min");
    promise.then(r => {
      store.dispatch({
        type: "SET_PROPERTIES",
        properties: r.data
      });
    })
  },

  selectProperties(properties) {
    store.dispatch({
      type: "SELECT_PROPERTIES",
      properties
    });
    setTimeout(() => {
      actions.fetchCards();
      actions.fetchUnits();
    }, 150);
  },

  fetchUnits() {
    const promise = axios.get(`/api/units?min=true&property_ids=${store.getState().selectedProperties.join(",")}`);
    promise.then(r => {
      store.dispatch({
        type: "SET_UNITS",
        units: r.data
      })
    });
  },

  fetchUnitInfo(id) {
    const promise = axios.get(`/api/units/${id}`);
    promise.then(r => {
      store.dispatch({
        type: "SET_UNIT_INFO",
        unit: r.data
      })
    });
  },

  setMode(mode) {
    store.dispatch({
        type: "SET_MODE",
        mode: mode
    })
  },

  adjustActualMoveOutDate(id, lease) {
    const promise = axios.patch(`/api/leases/${id}`, {lease});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Card successfully updated, you should now see the changes on the board", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Card NOT updated. Please make sure the information is correct.", args: {type: "error"}});
    });
    return promise;
  },

  addVacantUnitToBoard(card) {
    const promise = axios.post("/api/cards?vacant=true", {card});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Unit added to board. You can find it in the Not Ready section", args: {type: "success"}})
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: "error"}
      });
    });
    return promise;
  },

  createCard(params) {
    const promise = axios.post("/api/cards", {card: params});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Card successfully created", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Card NOT created. Please make sure the information is correct.", args: {type: "error"}});
    });
    return promise;
  },

  createCardItem(params) {
    const promise = axios.post("/api/card_items", {card_item: params});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Card Item successfully created and added to card", args: {type: "success"}});
    });
    promise.catch(e => {
      snackbar({message: `Card Item NOT created. Error: ${e.response.data.error}`, args: {type: "error"}});
    });
    return promise;
  },

  updateCardItem(params, type) {
    const promise = axios.patch(`/api/card_items/${params.id || "create"}`, {card_item: params, [type]: true});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Card item successfully updated", args: {type: "success"}});
    });
    promise.catch(e => {
      console.log(e.response.data.error);
      snackbar({message: "Something went wrong and the item was not updated.", args: {type: "error"}});
    });
    return promise;
  },

  updateCard(params) {
    const promise = axios.patch("/api/cards/" + params.id, {card: params});
    promise.then(() => {
      actions.fetchCards();
      snackbar({message: "Card successfully updated", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Card NOT updated. Please make sure the information is correct.", args: {type: "error"}});
    });
    return promise;
  },
};

export default actions;
