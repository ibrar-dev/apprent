import React from 'react';
import {Input, Button} from 'reactstrap';
import Select from '../../../../../components/select';
import actions from '../../../actions';

class Vehicle extends React.Component {
  state = {...this.props.vehicle};

  toggleMode() {
    this.setState({editMode: !this.state.editMode});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    actions.updateVehicle(this.state).then(() => {
      this.setState({editMode: false});
    })
  }

  toggleActive() {
    const {vehicle} = this.props;
    actions.updateVehicle({id: vehicle.id, active: !vehicle.active}).then(() => {
      this.setState({editMode: false});
    })
  }

  render() {
    const {vehicle} = this.props;
    const {editMode, make_model, color, license_plate, state} = this.state;
    const change = this.change.bind(this);
    if (editMode) {
      return <tr>
        <td>
          <Input value={make_model} name="make_model" onChange={change}/>
        </td>
        <td>
          <Input value={color} name="color" onChange={change}/>
        </td>
        <td>
          <Input value={license_plate} name="license_plate" onChange={change}/>
        </td>
        <td>
          <Select value={state} name="state" onChange={change} options={USSTATES}/>
        </td>
        <td>
          <Button color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </td>
        <td/>
      </tr>;
    }
    return <tr className={vehicle.active ? '' : 'text-muted'}>
      <td className="align-middle">
        {vehicle.make_model}
      </td>
      <td className="align-middle">
        {vehicle.color}
      </td>
      <td className="align-middle">
        {vehicle.license_plate}
      </td>
      <td className="align-middle">
        {vehicle.state}
      </td>
      <td className="align-middle">
        <Button color="info" onClick={this.toggleMode.bind(this)}>
          Edit
        </Button>
      </td>
      <td>
        <Button className="nowrap" color="danger" onClick={this.toggleActive.bind(this)}>
          Make {vehicle.active ? 'Inactive' : 'Active'}
        </Button>
      </td>
    </tr>;
  }
}

export default Vehicle;