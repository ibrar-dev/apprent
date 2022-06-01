import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from 'react-router-dom'
import JournalEntriesApp from "./components";
import ReactDOM from "react-dom";
import store from "./store";
import actions from './actions';

if (document.getElementById("journal-entries-app")) {
  actions.fetchJournalEntries();
  actions.fetchAccounts();
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <JournalEntriesApp/>
      </BrowserRouter>
    </Provider>,
    document.getElementById("journal-entries-app")
  )
}
