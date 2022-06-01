import React from "react";
import {Table, Button, Input} from 'reactstrap';
import Select from '../../../components/select';
import actions from "../actions";
import {toCurr} from '../../../utils';

const statusOptions = [
  {value: 'MODEL', label: 'MODEL'},
  {value: 'RENO', label: 'RENO'},
  {value: 'DOWN', label: 'DOWN'},
  {value: null, label: 'None'}
];

class UnitSpecs extends React.Component {
  state = {...this.props.unit};

  reset() {
    this.setState({...this.props.unit, editMode: false});
  }

  save() {
    const {feature_ids, floor_plan_id} = this.state;
    const {floorPlans} = this.props;
    let valid = true;
    if (floor_plan_id) {
      let featureIds = [...feature_ids];
      const floorPlan = floorPlans.filter(fp => fp.id === floor_plan_id)[0];
      feature_ids.forEach(id => {
        if (floorPlan.feature_ids.includes(id)) {
          featureIds = featureIds.filter(fid => fid !== id);
          alert("Unit feature is already included in selected floor plan");
          valid = false;
        }
      });
      this.setState({feature_ids: featureIds});
    }
    if (valid) actions.updateUnit(this.state);
  }

  toggleEdit() {
    if (this.state.editMode) this.save();
    this.setState({editMode: !this.state.editMode});
  }

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  changeAddress(e) {
    const {...unit} = this.state;
    if (!unit.address) {
      unit.address = {};
    }
    unit.address[e.target.name] = e.target.value;
    this.setState({...unit});
  }

  render() {
    const {features, floorPlans} = this.props;
    const featureKey = {};
    features.forEach(f => featureKey[f.id] = f);
    const {editMode, ...unit} = this.state;
    const unitFeatures = features.length ? unit.feature_ids.map(id => featureKey[id]) : [];
    unitFeatures.sort((a, b) => a.name > b.name ? 1 : -1);
    const areaRate = this.props.unit.area_rate;
    const areaCharge = areaRate * unit.area;
    let price = areaCharge;
    const dlc = this.props.unit ? this.props.unit.dlc : null;
    let dlc_total = 0;
    return <div>
      <div className="mb-3 text-right mt-1">
        <Button color="info" onClick={this.toggleEdit.bind(this)}>
          {editMode ? 'Save ' : 'Edit '}
          {editMode ? null : <i className="fas fa-edit"/>}
        </Button>
        {editMode && <Button className="ml-2" color="danger" onClick={this.reset.bind(this)}>
          Cancel
        </Button>}
      </div>
      <Table className="m-0">
        <tbody>
        <tr>
          <th className="min-width nowrap align-middle">Unit Number</th>
          <td>
            <Input value={unit.number}
                   name="number"
                   type="string"
                   disabled={!editMode}
                   onChange={this.change.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">Status</th>
          <td>
            <Select value={unit.status}
                    name="status"
                    onChange={this.change.bind(this)}
                    disabled={!editMode}
                    options={statusOptions}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">SqFt</th>
          <td>
            <Input value={unit.area}
                   name="area"
                   type="number"
                   disabled={!editMode}
                   onChange={this.change.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">Floor Plan</th>
          <td>
            <Select value={unit.floor_plan_id}
                    name="floor_plan_id"
                    onChange={this.change.bind(this)}
                    disabled={!editMode}
                    options={floorPlans.map(f => {
                      return {value: f.id, label: f.name};
                    })}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">Unit Features</th>
          <td>
            <Select value={unit.feature_ids} closeMenuOnSelect={false} name="feature_ids"
                    onChange={this.change.bind(this)} multi disabled={!editMode}
                    options={features.map(f => {
                      return {value: f.id, label: f.name};
                    })}/>
          </td>
        </tr>
        <tr className="border-bottom">
          <th className="min-width nowrap align-middle">Default Charges</th>
          <td style={{display: 'flex'}}>
            <ul style={{minWidth: 300}}>
              {dlc && dlc.map(c => {
                dlc_total += c.price;
                  return <li key={c.id} className="d-flex justify-content-between">
                      <span>{c.name}</span>
                      <span>${c.price}</span>
                  </li>
              })}
              {dlc && <div style={{minWidth: 300}} className="d-flex justify-content-between">
                <strong>Total</strong>
                <span>${dlc_total}</span>
              </div>}
            </ul>
          </td>
        </tr>
        </tbody>
      </Table>
      <h3>Address</h3>
      <Table>
        <tbody>
        <tr>
          <th className="min-width nowrap align-middle">Street</th>
          <td>
            <Input value={unit.address ? (unit.address.street || '') : ''}
                   name="street"
                   type="text"
                   disabled={!editMode}
                   onChange={this.changeAddress.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">City</th>
          <td>
            <Input value={unit.address ? (unit.address.city || '') : ''}
                   name="city"
                   type="text"
                   disabled={!editMode}
                   onChange={this.changeAddress.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">State</th>
          <td>
            <Input value={unit.address ? (unit.address.state || '') : ''}
                   name="state"
                   type="text"
                   disabled={!editMode}
                   onChange={this.changeAddress.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">Zip Code</th>
          <td>
            <Input value={unit.address ? (unit.address.zipcode || '') : ''}
                   name="zipcode"
                   type="text"
                   disabled={!editMode}
                   onChange={this.changeAddress.bind(this)}/>
          </td>
        </tr>
        <tr>
          <th className="min-width nowrap align-middle">Country</th>
          <td>
            <Input value={unit.address ? (unit.address.country || '') : ''}
                   name="country"
                   type="text"
                   disabled={!editMode}
                   onChange={this.changeAddress.bind(this)}/>
          </td>
        </tr>
        </tbody>
      </Table>

      <h3>Unit Value</h3>
      <Table>
        <tbody>
        {floorPlans.map(fp => {
          if (fp.id === unit.floor_plan_id) {
            price = price + parseFloat(fp.price);
            return <tr key={unit.floor_plan_id}>
              <th className="min-width nowrap align-middle">
                Floor Plan: {fp.name}
              </th>
              <td>{toCurr(fp.price)}</td>
            </tr>
          }
          return null;
        })}
        {unitFeatures.map(feature => {
          price = price + parseFloat(feature.price);
          return <tr key={feature.id}>
            <th className="min-width nowrap align-middle">
              {feature.name}
            </th>
            <td>{toCurr(feature.price)}</td>
          </tr>
        })}
        <tr>
          <th className="min-width nowrap align-middle">
            SqFt charge
          </th>
          <td>{toCurr(areaCharge)} ({toCurr(areaRate)} X {unit.area} sqft)</td>
        </tr>
        <tr style={{background: '#f5f5f5'}}>
          <th className="min-width nowrap align-middle">
            Total Rent
          </th>
          <td>{toCurr(price)}</td>
        </tr>
        </tbody>
      </Table>
    </div>;
  }
}

export default UnitSpecs
