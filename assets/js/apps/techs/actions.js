import axios from "axios";
import store from "./store";
import moment from "moment";
import setLoading from "../../components/loading";
import snackbar from "../../components/snackbar";

let actions = {
  initialLoad() {
    setLoading(true);
    actions.fetchTechs();
    actions.fetchStocks();
    actions.fetchProperties();
    actions.fetchCategories();
    setLoading(false);
  },
  fetchTechs() {
    const promise = axios.get("/api/techs?tech");
    promise.then(r => {
      store.dispatch({
        type: "SET_TECHS",
        techs: r.data,
      });
    });
  },
  fetchProperties() {
    const promise = axios.get("/api/property_meta");
    promise.then(r => {
      store.dispatch({
        type: "SET_PROPERTIES",
        properties: r.data,
      });
    });
  },
  fetchCategories() {
    const promise = axios.get("/api/categories");
    promise.then(r => {
      store.dispatch({
        type: "SET_CATEGORIES",
        categories: r.data,
      });
    });
  },
  fetchStocks() {
    const promise = axios.get("/api/stocks");
    promise.then(r => {
      store.dispatch({
        type: "SET_STOCKS",
        stocks: r.data,
      });
    });
  },
  fetchTechInfo(tech_id) {
    setLoading(true);
    const promise = axios.get(`/api/techs/${tech_id}?detailed_info`);
    promise.then(r => {
      store.dispatch({
        type: "SET_TECH",
        tech: r.data,
      });
      actions.reduceAssignments(r.data.assignments, moment("2018-04-01T00:00:00.000"), moment());
      actions.fetchPastSixMonths(tech_id);
      setLoading(false);
    });
  },
  reduceAssignments(assignments, startDate, endDate) {
    if (assignments.length < 1) return null;
    let sorted = {in_progress: [], on_hold: [], withdrawn: [], rejected: [], revoked: [], completed: [], callback: []};
    assignments.filter(assignment => moment.utc(assignment.inserted_at).isBetween(startDate, endDate) || moment.utc(assignment.completed_at).isBetween(startDate, endDate) || moment.utc(assignment.confirmed_at).isBetween(startDate, endDate) || moment.utc(assignment.updated_at).isBetween(startDate, endDate)).forEach(a => {
      if (a) {
        sorted[a.status].push(a);
      }
    });
    store.dispatch({
      type: "SET_ASSIGNMENTS",
      assignments: sorted,
    });
  },
  fetchPastSixMonths(techId) {
    const promise = axios.get(`/api/techs/${techId}?pastStats`);
    promise.then(r => {
      store.dispatch({
        type: "SET_HISTORY",
        stats: r.data,
      });
    });
  },
  searchForMaterials(term) {
    setLoading(true);
    const promise = axios.get(`/api/materials?search=${term}`);
    promise.then(r => {
      store.dispatch({
        type: "SET_SEARCH_RESULTS",
        results: r.data,
      });
      setLoading(false);
    });
  },
  sendToTech(toolbox_item, search) {
    const promise = axios.post("/api/toolbox_items?adminAdd", {toolbox_item});
    promise.then(r => {
      snackbar({
        message: "Item successfully added to techs toolbox",
        args: {type: "success"},
      });
      actions.fetchTechInfo(toolbox_item.tech_id);
      actions.searchForMaterials(search);
    });
    promise.catch(() => {
      actions.searchForMaterials(search);
      snackbar({
        message: "Item successfully added to techs toolbox",
        args: {type: "success"},
      });
    });
  },
  returnItem(id, tech_id) {
    const promise = axios.delete(`/api/toolbox_items/${id}`);
    promise.then(r => {
      actions.fetchTechInfo(tech_id);
    });
  },

  returnMaterial(id, tech_id, stock_id) {
    const promise = axios.patch(`/api/toolbox_items/${id}`,{ return_stock:  stock_id});
    promise.then(r => {
      actions.fetchTechInfo(tech_id);
    });
  },
  saveNewTech: (name, phone_number, email, type, property_ids) => {
    const body = {tech: {category_ids: [], name, email, phone_number, type, property_ids}};
    return axios.post("/api/techs", body)
  },
  setPassCode(tech) {
    if (!tech.pass_code || confirm(`${tech.name} already has a pass code of ${tech.pass_code}.  Resetting will invalidate this code and set a new one. Proceed?`)) {
      const promise = axios.patch("/api/techs/" + tech.id, {pass_code: true});
      promise.then(() => {
        actions.fetchTechs();
        alert("Pass code set!");
      });
      return promise;
    }
  },
  updateTech(id, tech) {
    const promise = axios.patch(`/api/techs/${id}`, tech);
    promise.then(() => {
      actions.fetchTechs();
      actions.fetchTechInfo(id);
    });
    return promise;
  },
  changeTech(tech, params) {
    const body = {tech: {category_ids: params}};
    const promise = axios.patch(`/api/techs/${tech.id}`, body);
    promise.then(actions.fetchTechInfo(tech.id));
    return promise;
  },
  selectAllCategories(tech_id) {
    const promise = axios.patch(`/api/techs/${tech_id}?all_categories`);
    promise.then(() => {
      actions.fetchTechInfo(tech_id);
    });
  },
  // viewTech(tech) {
  //   generators.viewTech(tech);
  // },
  setMode(mode) {
    store.dispatch({
      type: "SET_MODE",
      mode,
    });
  },
};

export default actions;
