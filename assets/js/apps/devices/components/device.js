import React from 'react';
import {connect} from 'react-redux';
import {Button} from 'reactstrap';
import Code from './code';
import actions from '../actions';
import Select from '../../../components/select';
import confirmation from '../../../components/confirmationModal';

class Device extends React.Component {
  state = {};

  deleteDevice() {
    confirmation('Delete this device?').then(actions.deleteDevice.bind(null, this.props.device));
  }

  toggleCode() {
    this.setState({showCode: !this.state.showCode});
  }

  change({target: {name, value}}) {
    actions.updateDevice({...this.props.device, [name]: value});
  }

  render() {
    const {device, properties} = this.props;
    const {showCode} = this.state;
    return <tr>
      <td className="align-middle">
        <a onClick={this.deleteDevice.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="align-middle">{device.name}</td>
      <td className="align-middle">
        <Select multi name="property_ids" value={device.property_ids}
                onChange={this.change.bind(this)}
                options={properties.map(p => {
                  return {label: p.name, value: p.id};
                })}/>
      </td>
      <td>
        <Button onClick={this.toggleCode.bind(this)} color="info">
          Show Code
        </Button>
      </td>
      {showCode && <Code device={device} toggle={this.toggleCode.bind(this)}/>}
    </tr>;
  }
}

export default connect(({properties}) => {
  return {properties};
})(Device);