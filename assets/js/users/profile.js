import axios from 'axios';

export default {
  updateProfile(params) {
    return axios.patch('/profile', {account: params});
  },
  updateAutopay(params) {
    return axios.patch('/profile', {autopay: params});
  }
};