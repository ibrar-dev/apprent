import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property) actions.viewProperty(r.data[0]);
    })
  },
  viewProperty(property) {
    setLoading(true);
    store.dispatch({
      type: 'OPEN_PROPERTY',
      property
    });
    const promise = axios.get(`/api/resident_events?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_EVENTS',
        events: r.data
      });
      setLoading(false);
    })
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to fetch events',
        args: {type: 'Warning'}
      })
    })
  },
  createEvent(params, property) {
    setLoading(true);
    const promise = axios.post('/api/resident_events', {resident_event: params});
    promise.then(() => {
      actions.viewProperty(property);
      snackbar({
        message: 'Event successfully created',
        args: {type: 'success'}
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Event not created',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  updateEvent(params, property, id) {
    setLoading(true);
    const promise = axios.patch(`/api/resident_events/${id}`, {resident_event: params});
    promise.then(() => {
      actions.viewProperty(property);
      snackbar({
        message: 'Event successfully updated',
        args: {type: 'success'}
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Event not updated',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  showEvent(eventID) {
    if (eventID) {
      setLoading(true);
      const promise = axios.get(`/api/resident_events/${eventID}`);
      promise.then(r => {
        store.dispatch({
          type: 'SET_EVENT',
          event: r.data
        });
        setLoading(false)
      });
      promise.catch(() => {
        snackbar({
          message: 'Failed to get Event Info',
          args: {type: 'error'}
        });
        setLoading(false);
      })
    } else {
      store.dispatch({
        type: 'SET_EVENT',
        event: null
      })
    }
  },
  registerResident(resident_event_attendance) {
    setLoading(true);
    const promise = axios.post('/api/resident_event_attendances', {resident_event_attendance});
    promise.then(() => {
      actions.showEvent(resident_event_attendance.resident_event_id);
    });
    promise.catch(() => {
      snackbar({
        message: 'Failed to register resident. Please make sure the resident is not registered already.',
        args: {type: 'error'}
      });
      setLoading(false);
    })
  },
  deleteEvent(id, property){
    const promise = axios.delete(`/api/resident_events/${id}`);
    promise.then(() => actions.viewProperty(property))
    return promise;
  }
};

export default actions;