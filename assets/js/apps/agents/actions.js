import axios from 'axios';
import store from "./store"

let actions = {
  setAgents: (agents)=>{
    const action = {
      type: 'SET_AGENTS',
      agents
    };
    store.dispatch(action)
  },
  addAgent: (agent)=>{
    const action = {
      type: 'ADD_AGENT',
      agent
    };
    store.dispatch(action)
  },
  removeAgent: (agent)=>{
    const action = {
      type: 'REMOVE_AGENT',
      agent
    };
    store.dispatch(action)
  },
  deleteAgent: (agent)=>{
    const promise = axios.delete(`/api/agents/${agent.id}`);
    promise.then(r => actions.removeProspect(agent));
    return promise;
  },
  getAgents: ()=>{
    const promise = axios.get('/api/agents');
    promise.then(r => actions.setAgents(r.data));
    return promise;
  },
  saveAgent: (prospect)=>{
    const promise = axios.post('/api/agents', {prospect});
    promise.then(r => actions.addAgent(r.data)).catch(e=>e);
    return promise;
  },
  updateAgentValues: (newVals)=>{
    const action = {
      type: 'UPDATE_AGENT',
      newVals
    };
    store.dispatch(action)
  },
  updateAgent: (a)=>{
    let {id, ...agent} = a;
    let promise;
    if(id === 0){
      promise = axios.post('/api/agents/', {agent: agent});
      promise.then((r) => {
        actions.removeAgent(a);
        actions.addAgent(r.data);
      }).catch(e=>e);
    }else{
      promise = axios.patch(`/api/agents/${id}`, {agent: agent});
      promise.then(r => actions.updateAgentValues(r.data)).catch(e=>e);
    }

    return promise;
  }
};

export default actions
