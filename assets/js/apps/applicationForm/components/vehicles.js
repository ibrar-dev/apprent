import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import Vehicle from '../models/vehicle';
import utils from './utils';

class VehicleForm extends React.Component {
  editField(e) {
    actions.editCollection('vehicles', this.props.index, e.target.name, e.target.value);
  }

  deleteVehicle() {
    actions.deleteCollection('vehicles', this.props.vehicle._id);
  }

  render() {
    const userField = utils.userField.bind(this, this.props.vehicle);
    const {lang} = this.props;
    return <div className="card">
      <div className="card-header">
        {lang.vehicle} #{this.props.index + 1}
        <a className="delete-button" onClick={this.deleteVehicle.bind(this)}>
          <i className="fas fa-trash"/>
        </a>
      </div>
      <div className="card-body pt-0">
        {userField('make_model', lang.model)}
        {userField('color', lang.color)}
        {userField('license_plate', lang.license)}
        {userField('state', lang.state, 'state')}
      </div>
    </div>
  }
}

class Vehicles extends React.Component {
  addVehicle() {
    actions.addToCollection('vehicles', new Vehicle());
  }

  render() {
    const {vehicles} = this.props.application;
    const {lang} = this.props;
    return <div>
      {vehicles.map((vehicle, index) => {
        return <VehicleForm key={vehicle._id} lang={lang} index={index} vehicle={vehicle}/>;
      })}
      <div className="add-button" onClick={this.addVehicle.bind(this)}>
        <button>
          <i className="fas fa-plus"/>
        </button>
        {lang.add_vehicle}
      </div>
    </div>;

  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Vehicles);