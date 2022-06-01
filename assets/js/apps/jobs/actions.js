import axios from 'axios';
import store from "./store";
import setLoading from "../../components/loading";

let actions = {
  fetchJobs() {
    setLoading(true);
    axios.get('/api/jobs').then(r => {
      store.dispatch({
        type: 'SET_JOBS',
        jobs: r.data,
      });
      setLoading(false);
    });
  },
  fetchJobTypes() {
    axios.get('/api/jobs?types=true').then(r => {
      store.dispatch({
        type: 'SET_JOB_TYPES',
        jobTypes: r.data,
      });
    });
  },
  updateJob(params) {
    setLoading(true);
    const promise = axios.patch(`/api/jobs/${params.id}`, {job: params});
    promise.then(actions.fetchJobs);
    return promise;
  },
  createJob(params) {
    setLoading(true);
    const promise = axios.post('/api/jobs', {job: params});
    promise.then(actions.fetchJobs);
    return promise;
  },
  deleteJob(id) {
    setLoading(true);
    const promise = axios.delete('/api/jobs/' + id);
    promise.then(actions.fetchJobs);
    return promise;
  }
};

export default actions
