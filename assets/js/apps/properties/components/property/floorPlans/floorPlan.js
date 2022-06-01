import React from 'react';
import {Input, Button} from 'reactstrap';
import Select from '../../../../../components/select';
import EditUnits from './editUnits';
import actions from "../../../actions";
import EditCharges from './editCharges';
import canEdit from '../../../../../components/canEdit';

class FloorPlan extends React.Component {
  state = {
    floorPlan: this.props.floorPlan,
    charges: false
  };

  static getDerivedStateFromProps(state, props) {
    return {floorPlan: props.floorPlan}
  }

  toggleEditUnits() {
    this.setState({...this.state, editUnits: !this.state.editUnits});
  }

  toggleEdit(shouldSave) {
    if (shouldSave) actions.saveFloorPlan(this.state.floorPlan);
    this.setState({...this.state, editMode: !this.state.editMode});
  }

  toggleCharges() {
    this.setState({...this.state, charges: !this.state.charges})
  }

  change({target: {name, value}}) {
    this.setState({...this.state, floorPlan: {...this.state.floorPlan, [name]: value}});
  }

  deleteFloorPlan() {
    if (confirm('Delete this floor plan?')) {
      actions.deleteFloorPlan(this.state.floorPlan);
    }
  }

  cancel() {
    if (!this.state.floorPlan.id) return this.deleteFloorPlan();
    this.setState({...this.state, floorPlan: this.props.floorPlan, editMode: false});
  }

  render() {
    const {features} = this.props;
    const {floorPlan, editUnits, charges} = this.state;
    const change = this.change.bind(this);
    const editMode = this.state.editMode || !floorPlan.id;
    return (
      <tr className="link-row">
        <td className="align-middle">
          {canEdit(["Regional", "Super Admin", "Accountant"]) && <a onClick={this.deleteFloorPlan.bind(this)}>
            <i className="fas fa-times text-danger"/>
          </a>}
        </td>
        <td>
          <Input value={floorPlan.name} onChange={change} name="name" disabled={!editMode}/>
        </td>
        <td>
          <Select multi={true}
                  disabled={!editMode}
                  value={floorPlan.feature_ids}
                  name="feature_ids"
                  onChange={change}
                  options={features.map(f => { return {label: f.name, value: f.id}; })} />
        </td>
        <td>
          <div className="d-flex">
            <Button onClick={this.toggleEdit.bind(this, editMode)} color="info">
              {editMode ? 'Save' : 'Edit'}
            </Button>
            {editMode && <Button onClick={this.cancel.bind(this)} color="danger" className="ml-3">
              Cancel
            </Button>}
          </div>
        </td>
        <td>
          <Button onClick={this.toggleEditUnits.bind(this)}>
            {floorPlan.units && floorPlan.units.length} Units
          </Button>
        </td>
        <td>
          <Button onClick={this.toggleCharges.bind(this)}>
            {floorPlan.charges && floorPlan.charges.length} Charges
          </Button>
        </td>
        {editUnits && <EditUnits feature={floorPlan} floorPlan={true} toggle={this.toggleEditUnits.bind(this)}/>}
        {charges && <EditCharges floorPlan={floorPlan} toggle={this.toggleCharges.bind(this)} />}
      </tr>
    )
  }
}

export default FloorPlan;