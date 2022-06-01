import React from 'react';
import {connect} from 'react-redux';
import {Button} from 'reactstrap';
import Device from './device';
import NewDevice from './newDevice';
import Pagination from '../../../components/pagination';
import actions from "../../tenants/actions";
import {safeRegExp} from "../../../utils";

const headers = [
  {label: '', min: true},
  {label: 'Name', sort: 'name'},
  {label: 'Properties'},
  {label: '', min: true}
];

class Devices extends React.Component {
  state = {
    filter: ''
  };

  changeFilter(e) {
    this.setState({...this.state, filter: e.target.value})
  }

  _filters() {
    const {filter} = this.state;
    return <input className="form-control" value={filter} onChange={this.changeFilter.bind(this)}/>;
  }

  _filtered(devices) {
    const {filter} = this.state;
    const test = safeRegExp(filter);
    return devices.filter(d => test.test(d.name));
  }

  toggleNew() {
    this.setState({...this.state, newDevice: !this.state.newDevice});
  }

  render() {
    const {devices} = this.props;
    const {newDevice} = this.state;
    return <React.Fragment>
      <Pagination
        title={<div>Devices <Button color="success" size="sm" className="mt-0 ml-2" onClick={this.toggleNew.bind(this)}>
          Register New
        </Button></div>}
        collection={this._filtered(devices)}
        component={Device}
        headers={headers}
        filters={this._filters()}
        field="device"
      />
      {newDevice && <NewDevice toggle={this.toggleNew.bind(this)}/>}
    </React.Fragment>;
  }
}

export default connect(({devices}) => {
  return {devices};
})(Devices);