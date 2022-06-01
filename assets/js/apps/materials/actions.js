import axios from 'axios';
import store from "./store"
import snackbar from '../../components/snackbar';
import setLoading from '../../components/loading';

let actions = {
  fetchStocks() {
    setLoading(true);
    const promise = axios.get('/api/stocks');
    promise.then(r => {
      store.dispatch({
        type: 'SET_STOCKS',
        stocks: r.data.stocks,
      });
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data.properties,
      });
      setLoading(false);
      const stock = store.getState().stock;
      if (stock) actions.fetchStock(stock.id);
    });
    promise.catch(() => {
      snackbar({message: "DB Connection lost, retrying", args: {type: "error"}});
      actions.fetchStocks();
    })
  },
  fetchMaterialTypes() {
    axios.get('/api/material_types').then(r => {
      store.dispatch({
        type: 'SET_TYPES',
        types: r.data,
      });
    })
  },
  setReportStatus(value) {
    store.dispatch({
      type: 'SET_REPORT',
      value: value
    })
  },
  fetchMaterialLogs(stock, start_date, end_date) {
    const promise = axios.get(`/api/material_logs?stock=${stock}&startDate=${start_date}&endDate=${end_date}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_LOGS',
        logs: r.data
      });
    });
  },
  fetchStockInventory(stock_id, start_date, end_date) {
    if(end_date > "2018-10-24"){
      const promise = axios.get(`/api/toolbox_items?stock_id=${stock_id}&start_date=${start_date}&end_date=${end_date}`);
      promise.then(r => {
        store.dispatch({
          type: 'SET_LOGS',
          logs: r.data
        });
      })
    }
    else{
      const stock = stock_id
      const promise = axios.get(`/api/material_logs?stock=${stock}&startDate=${start_date}&endDate=${end_date}`);
      promise.then(r => {
        store.dispatch({
          type: 'SET_LOGS',
          logs: r.data
        });
      })
    }
  },
  createStock({name, propertyIds: property_ids}) {
    const promise = axios.post('/api/stocks', {stock: {name, property_ids}});
    promise.then(() => {
      actions.fetchStocks();
      snackbar({message: "Stock Location successfully created", args: {type: "success"}})
    });
    return promise;
  },
  createMaterial(stockId, params) {
    const body = {material: {...params, stock_id: stockId}};
    const promise = axios.post('/api/materials', body);
    promise.then(() => {
      actions.fetchMaterials(stockId);
      snackbar({message: "Material successfully created", args: {type: "success"}})
    });
    return promise;
  },
  viewReport(value) {
    store.dispatch({
      type: 'SET_REPORT',
      value: value
    })
  },
  fetchMaterials(stock_id) {
    setLoading(true);
    actions.fetchStock(stock_id);
    const promise = axios.get(`/api/stocks/${stock_id}?materials`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_MATERIALS',
        materials: r.data
      });
      setLoading(false);
    })
  },
  fetchStock(id) {
    // const stock = store.getState().stocks.filter(s => s.id === id)[0] || null;
    const promise = axios.get(`/api/stocks/${id}?stock`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_STOCK',
        stock: r.data
      })
    })
  },
  deleteMaterial(id) {
    const promise = axios.delete('/api/materials/' + id);
    promise.then(() => {
      actions.fetchStocks();
      snackbar({message: "Material successfully deleted", args: {type: "error"}})
    });
    return promise;
  },
  updateMaterial(params) {
    const {id, ...data} = params;
    const promise = axios.patch('/api/materials/' + id, {material: data});
    promise.then(() => {
      actions.fetchMaterials(params.stock_id);
      snackbar({message: "Material successfully updated", args: {type: "success"}})
    });
    return promise;
  },
  updateImage(id, stock_id, material, type) {
    const promise = axios.patch(`/api/${type}/${id}`, material);
    promise.then(() => {
      actions.fetchStocks();
      actions.fetchMaterials(stock_id);
      snackbar({message: "Material successfully updated", args: {type: "success"}})
    });
    return promise;
  },
  updateStock(params) {
    const {id, ...data} = params;
    const promise = axios.patch('/api/stocks/' + id, {stock: data});
    promise.then(() => {
      actions.fetchStocks();
      snackbar({message: "Stock successfully updated", args: {type: "success"}})
    });
    return promise;
  },
  deleteStock(id) {
    const promise = axios.delete('/api/stocks/' + id);
    promise.then(() => {
      actions.fetchStocks();
      snackbar({message: "Stock successfully deleted", args: {type: "error"}})
    });
    return promise;
  },
  setFilter(filter) {
    store.dispatch({
      type: 'SET_FILTER',
      filter
    });
  },
  shopVerify(password, stock_id){
    const promise = axios.post(`/api/toolbox_items`, password);
    promise.then(r => {
      localStorage.setItem("@tech", JSON.stringify(r.data));
      store.dispatch({
          type: "SET_SHOP_USER",
          user:r.data
      });
      actions.fetchShopItems(stock_id);
        actions.fetchToolBoxItems(r.data.id);
        actions.resetTime();
        snackbar({message: `Signed in, welcome ${r.data.name}`, args: {type: "success"}})
    });
    promise.catch(() => {
        snackbar({message: "Invalid Identifier", args: {type: "error"}})
    });
  },
  shopCheckout(stock_id, tech_id){
    const promise = axios.patch(`/api/toolbox_items/${tech_id}`,{stock_id:stock_id});
      promise.then(r => {
          actions.fetchShopItems(stock_id);
          actions.fetchCartItems(stock_id,tech_id)
          snackbar({message: `Sucessfully checked out of shop`, args: {type: "success"}})
      });
      promise.catch(() => {
          snackbar({message: "Error checking out", args: {type: "error"}})
      });
  },
  fetchShopItems(stock_id){
    const promise = axios.get(`/api/toolbox_items?stock_id=${stock_id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_SHOP_MATERIALS',
        materials: r.data
        });
    });
  },
  addItemToCart(item,stock_id,tech_id){
      const promise = axios.post(`/api/toolbox_items`,{toolbox_item:{stock_id: stock_id, material_id: item.id, tech_id: tech_id}});
      promise.then(r => {
        actions.fetchCartItems(stock_id,tech_id);
      });
  },
  returnItems(data){
      var tech = JSON.parse(localStorage.getItem("@tech"));
      const promise = axios.patch(`/api/toolbox_items/${data.item_id}`,{return_stock: data.stock_id});
      promise.then(r => {
          actions.fetchToolBoxItems(tech.id);
          actions.fetchShopItems(data.stock_id);
          snackbar({message: `Items successfully returned `, args: {type: "success"}})
      });
      promise.catch(() => {
          snackbar({message: "Error returning items", args: {type: "error"}})
      });
  },
  removeItemFromCart(id, stock_id, tech_id){
      const promise = axios.patch(`/api/toolbox_items/${id}`, {return_from_cart: stock_id});
      promise.then(r => {
          actions.fetchCartItems(stock_id,tech_id);
      });
  },
  fetchCartItems(stock_id,tech_id){
      const promise = axios.get(`/api/toolbox_items?tech_id=${tech_id}&stock_id=${stock_id}`);
      promise.then(r => {
        store.dispatch({
          type: 'SET_SHOP_CART',
          cart: r.data
        });
      });
  },
  clearCart(stock_id){
      var tech = JSON.parse(localStorage.getItem("@tech"));
      const promise = tech && axios.patch(`/api/toolbox_items/${tech.id}`,{remove_all:"remove_all"});
      promise.then(() => {
          actions.fetchCartItems(stock_id,tech.id);
          snackbar({message: "Cart successfully cleared", args: {type: "success"}})
      });
      promise.catch(() => {
          snackbar({message: "Error clearing cart", args: {type: "error"}})
      });
  },
  fetchToolBoxItems(tech_id){
      const promise = axios.get(`/api/toolbox_items?tech_id=${tech_id}`);
      promise.then(r => {
          store.dispatch({
              type: 'SET_TOOL_BOX',
              tools: r.data
          });
      });
  },

  checkIfLoggedIn(stock_id) {
    let tech = JSON.parse(localStorage.getItem("@tech"));
    if (tech) {
      const data = tech;
      actions.fetchShopItems(stock_id);
      actions.fetchCartItems(stock_id, data.id);
      actions.fetchToolBoxItems(data.id);
      actions.fetchStock(stock_id);
      store.dispatch({
        type: "SET_SHOP_USER",
        user: data
      })
    } else {
      actions.signOutOfShop();
    }
  },
  signOutOfShop(stock_id) {
    actions.resetTime();
    let tech = JSON.parse(localStorage.getItem("@tech"));
    const promise = tech && axios.patch(`/api/toolbox_items/${tech.id}`,{remove_all:"remove_all"});
    localStorage.setItem("@tech", null);
    promise && promise.then(r => {
        actions.fetchCartItems(stock_id,tech.id);
        store.dispatch({
            type: "SET_SHOP_USER",
            user: {}
        })
    })
  },
  resetTime() {
    store.dispatch({
      type: "RESET_TIME",
      time: 300
    })
  },
  tickTime() {
    store.dispatch({
      type: "RESET_TIME",
      time: store.getState().timeoutTime - 1
    })
  },
  createType(type) {
    const promise = axios.post('/api/material_types', {type});
    promise.then(() => {
      actions.fetchMaterialTypes();
      snackbar({message: "Type successfully created", args: {type: "success"}})
    });
    return promise;
  },
  importCSV(name, stockId) {
    const promise = axios.post('/api/stocks', {import_csv: {name, stock_id: stockId}});
    promise.then(actions.fetchStocks);
    return promise;
  },
  sendMaterial(log, material) {
    const promise = axios.post('/api/material_logs', {log: log, material: material});
    promise.then(actions.fetchMaterials(log.stock_id));
    return promise;
  },
  fetchMaterialInfo(id) {
    setLoading(true);
    const promise = axios.get(`/api/materials/${id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_MATERIAL_INFO',
        material: r.data
      });
      setLoading(false);
    })
  },
  undoReturn(id, material_log) {
    const promise = axios.patch(`/api/material_logs/${id}?cancel`, {material_log});
    promise.then(() => {
      actions.fetchMaterialInfo(id);
    })
  },
  returnMaterial(id, material_log) {
    const promise = axios.patch(`/api/material_logs/${id}?return=`, {material_log});
    promise.then(() => {
      actions.fetchMaterialInfo(id);
      snackbar({message: "Material successfully returned", args: {type: "success"}})
    });
    promise.catch(() => {
      snackbar({message: "Material NOT returned", args: {type: "error"}})
    });
  },
  addToMaterialCart(m, type) {
    store.dispatch({
      type: `${type}_CART`,
      material: m
    })
  }
};

export default actions
