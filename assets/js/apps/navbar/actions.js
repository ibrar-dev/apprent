import axios from "axios/index";
import store from "./store";
import snackbar from "../../components/snackbar";

const actions = {
  fetchAdmin(id) {
    const promise = axios.get(`/api/admins/${id}`);
    promise.then((r) => actions.setAdmin(r.data));
    return promise;
  },
  updateProfile(profile) {
    const promise = profile.id ? axios.patch(`/api/admin_profile/${profile.id}`, {admin_profile: profile})
      : axios.post("/api/admin_profile", {admin_profile: profile});
    promise.then(() => {
      actions.fetchAdmin(window.user.id);
      snackbar({message: "Profile successfully updated", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Error updating cart", args: {type: "error"}});
    });
    return promise;
  },
  setAdmin(admin) {
    store.dispatch({
      type: "SET_ADMIN",
      admin,
    });
  },
  searchTenants(queryString) {
    return axios.get(`/api/tenants?search=${queryString}`);
  },
};

export default actions;
