import React from 'react';
import {withRouter} from 'react-router';
import {Link} from 'react-router-dom';
import Pagination from '../../../components/pagination';
import canEdit from "../../../components/canEdit";
import Material from "./material";
import NewMaterial from "./newMaterial";
import actions from '../actions';
import StockAlerts from './stockAlerts';
import NewOrder from './newOrder';
import {connect} from "react-redux";


class Materials extends React.Component {
  constructor(props) {
    const stock_id = props.history.location.pathname.split('/').pop();
    super(props);
    this.state = {report: false, stock_id: stock_id};
    actions.fetchStock(stock_id);
    actions.fetchMaterials(stock_id);
  }

  headers = [
    {label: '', sort: null, min: true},
    {label: 'Image', sort: null, min:true},
    {label: 'Reference Number', sort: 'ref_number'},
    {label: 'Name', sort: 'name'},
    {label: 'Cost', sort: 'cost', min: true},
    {label: 'Category', sort: 'type_id'},
    {label: 'Inventory', sort: 'inventory', min: true},
    {label: 'Per Item', sort: 'per_unit'},
    // {label: 'Edit', sort: null, min: true}
  ];

  newMaterial() {
    this.setState({...this.state, modal: !this.state.modal});
  }

  filterChange(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  toggleAlerts() {
    this.setState({...this.state, alerts: !this.state.alerts});
  }

  toggleNewOrder() {
    this.setState({...this.state, newOrder: !this.state.newOrder});
  }

  refreshMaterials() {
    // actions.fetchStocks();
    actions.fetchMaterials(this.state.stock_id);
  }

  render() {
    const {materials, stock} = this.props;
    const {modal, filterVal, alerts, newOrder} = this.state;
    const propertyLoggedIn = canEdit(["Property"]);
    const filter = new RegExp(filterVal, 'i');
    return <React.Fragment>
      <div className="mb-3">
        <Link to="/materials" className="btn btn-danger mr-1">
          <i className="fas fa-arrow-left"/>
        </Link>
        {!propertyLoggedIn && <React.Fragment><button className="btn btn-outline-success mr-1" onClick={this.newMaterial.bind(this)}>
          <i className="fas fa-plus" />
        </button>
        <button className="btn btn-outline-info mr-1" onClick={this.toggleAlerts.bind(this)}>
          <i className="fas fa-bell" />
        </button>
        <button className="btn btn-outline-info mr-1" onClick={this.refreshMaterials.bind(this)}>
          <i className="fas fa-sync" />
        </button></React.Fragment>}
        {stock && stock.id && propertyLoggedIn && <Link className="btn btn-outline-info" to={`/materials/${stock.id}/shop`} >
          <i className="fas fa-cart-plus" />
        </Link>}
      </div>
      <Pagination title={`${stock ? stock.name : ''} Inventory`}
                  collection={materials.filter(m => filter.test(m.ref_number) || filter.test(m.name))}
                  component={Material}
                  headers={this.headers}
                  filters={<input className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                  field="material">
      </Pagination>
      {modal && <NewMaterial close={this.newMaterial.bind(this)} stock={stock} />}
      {alerts && <StockAlerts toggle={this.toggleAlerts.bind(this)} />}
      {newOrder && <NewOrder close={this.toggleNewOrder.bind(this)} />}
    </React.Fragment>;
  }
}

export default withRouter(connect(({materialCart, materials, stock}) => {
  return {materialCart, materials, stock}
})(Materials));