import React from "react";
import {Provider} from "react-redux";
import ReactDOM from "react-dom";
import CardsApp from "./components";
import store from "./store";
import actions from "./actions";

if (document.getElementById("cards-app")) {
  actions.fetchProperties();
  actions.fetchTechs();
  actions.fetchVendors();
  actions.fetchVendorCategories();
  ReactDOM.render(
    <Provider store={store}>
      <CardsApp />
    </Provider>,
    document.getElementById("cards-app"),
  );
}
