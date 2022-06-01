import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter, Switch, Route} from "react-router-dom";
import ReactDOM from "react-dom";
import store from "./store";
import PaymentsIndex from "./components/paymentsIndexPage";
import Payment from "./components/show";
import PaymentForm from "./components/newDeposit";

if (document.getElementById("payments-app")) {
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <Switch>
          <Route exact path="/payments" component={PaymentsIndex} />
          <Route exact path="/payments/new" component={PaymentForm} />
          <Route exact path="/payments/:id" component={Payment} />
        </Switch>
      </BrowserRouter>
    </Provider>,
    document.getElementById("payments-app"),
  );
}
