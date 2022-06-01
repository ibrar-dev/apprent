import React from 'react';
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import store from "./store";
import PostsApp from './components';
import actions from './actions';

if (document.getElementById("posts-app")) {
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <PostsApp/>
    </Provider>,
    document.getElementById("posts-app")
  )
}