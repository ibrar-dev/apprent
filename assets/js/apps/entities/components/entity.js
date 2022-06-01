import React from 'react';
import {Label, Input, InputGroup, InputGroupAddon, Button} from 'reactstrap';
import actions from '../actions';

const resourceList = {
  tenants: 'Tenants',
  orders: 'Work Orders',
  units: 'Units',
  payments: 'Payments',
  applications: 'Rent Applications'
};

class Entity extends React.Component {
  state = {};

  changeProp({target: {checked: checked, value: propertyId}}) {
    const func = checked ? actions.attachProperty : actions.detachProperty;
    func(this.props.entity.id, propertyId);
  }

  changeName() {
    this.setState({...this.state, editMode: true, newName: this.props.entity.name});
  }

  handleNameChange(e) {
    this.setState({...this.state, newName: e.target.value});
  }

  saveName() {
    actions.updateEntity(this.props.entity.id, {name: this.state.newName}).then(() => {
      this.setState({...this.state, editMode: false});
    });
  }

  changeResources({target: {checked: checked, value: resource}}) {
    const {entity: {id, resources}} = this.props;
    const newResources = checked ? resources.concat([resource]) : resources.filter(r => r !== resource);
    actions.updateEntity(id, {resources: newResources});
  }

  render() {
    const {properties, entity} = this.props;
    const {editMode, newName} = this.state;
    return <tr>
      <td/>
      <td>
        {!editMode && entity.name}
        <br />
        {!editMode && <a className="text-info" onClick={this.changeName.bind(this)}>Change</a>}
        {editMode && <InputGroup>
          <Input value={newName} onChange={this.handleNameChange.bind(this)}/>
          <InputGroupAddon>
            <Button onClick={this.saveName.bind(this)}>
              Save
            </Button>
          </InputGroupAddon>
        </InputGroup>}
      </td>
      {/*<td>*/}
        {/*<div className="d-flex flex-column flex-wrap" style={{maxHeight: '150px'}}>*/}
          {/*{Object.keys(resourceList).map(r => {*/}
            {/*return <Label key={r} check>*/}
              {/*<Input type="checkbox"*/}
                     {/*value={r}*/}
                     {/*checked={entity.resources.indexOf(r) > -1}*/}
                     {/*onChange={this.changeResources.bind(this)}/> {resourceList[r]}*/}
            {/*</Label>;*/}
          {/*})}*/}
        {/*</div>*/}
      {/*</td>*/}
      <td>
        <div className="d-flex flex-column flex-wrap" style={{maxHeight: '150px'}}>
          {properties.map(p => {
            return <Label key={p.id} check>
              <Input type="checkbox"
                     value={p.id}
                     checked={entity.property_ids.indexOf(p.id) > -1}
                     onChange={this.changeProp.bind(this)}/> {p.name}
            </Label>;
          })}
        </div>
      </td>
    </tr>
  }
}

export default Entity;