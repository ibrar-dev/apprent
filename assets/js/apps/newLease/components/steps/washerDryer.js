import React from 'react';
import {Input, Card, CardBody, Label} from "reactstrap";

class WasherDryer extends React.Component {
  state = {
    otherType: !['Full Size', 'Stackable'].includes(this.props.lease.washer_type)
  };

  change({target: {name, value}}) {
    this.props.onChange(name, value);
  }

  changeType({target: {value}}) {
    if (!this.state.otherType && value === 'Other') {
      this.props.onChange('washer_type', '');
    } else if (value !== 'Other') {
      this.props.onChange('washer_type', value);
    }
    this.setState({otherType: value === 'Other'});
  }

  render() {
    const {lease} = this.props;
    const {otherType} = this.state;
    return <div>
      <h3>Other Items</h3>
      <Card>
        <CardBody>
          <div className="d-flex align-items-center mb-3">
            <Label className="nowrap mr-2 mb-0">Monthy Rent</Label>
            <Input value={lease.washer_rent || ''} name="washer_rent" type="number"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex flex-column mb-4">
            <label className="mb-2">
              <input type="radio" name="washer_type"
                     value="Full Size" disabled={lease.locked}
                     checked={lease.washer_type === 'Full Size'}
                     onChange={this.changeType.bind(this)}/> Full Size
            </label>
            <label className="mb-1">
              <input type="radio" name="washer_type"
                     value="Stackable" disabled={lease.locked}
                     checked={lease.washer_type === 'Stackable'}
                     onChange={this.changeType.bind(this)}/> Stackable
            </label>
            <div className="d-flex align-items-center">
              <label className="d-flex align-items-center mb-0 mr-2">
                <input type="radio" name="washer_type"
                       value="Other" disabled={lease.locked}
                       checked={otherType && !['Full Size', 'Stackable'].includes(lease.washer_type)}
                       onChange={this.changeType.bind(this)}/> <span className="ml-1"> Other</span>
              </label>
              <Input name="washer_type" value={otherType ? lease.washer_type || '' : ''}
                     onChange={this.change.bind(this)} disabled={lease.locked}
                     disabled={!otherType}/>
            </div>
          </div>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Washer Serial</Label>
            <Input value={lease.washer_serial || ''} name="washer_serial"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex align-items-center">
            <Label className="nowrap mr-2 mb-0">Dryer Serial</Label>
            <Input value={lease.dryer_serial || ''} name="dryer_serial"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
        </CardBody>
      </Card>
    </div>;
  }
}

export default WasherDryer;