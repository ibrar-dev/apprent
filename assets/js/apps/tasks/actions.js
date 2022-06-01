import axios from 'axios';
import store from "./store";
import setLoading from '../../components/loading';
import {toQueryString} from "../../utils";

const actions = {
  fetchTasks(params) {
    setLoading(true);
    const promise = axios.get('/api/tasks' + toQueryString(params));
    promise.then(r => {
      store.dispatch({
        type: 'SET_TASKS',
        tasks: r.data
      });
      setLoading(false);
    });
    return promise;
  }
};

export default actions
