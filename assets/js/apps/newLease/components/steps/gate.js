import React from 'react';
import {Card, CardBody, Label} from 'reactstrap';
import Checkbox from '../../../../components/fancyCheck';

class Gate extends React.Component {
  change({target: {name, checked}}) {
    this.props.onChange(name, checked);
  }

  render() {
    const {lease} = this.props;
    return <div>
      <h3>Gate Access</h3>
      <Card>
        <CardBody>
          <div className="d-flex align-items-center">
            <div className="d-flex">
              <Checkbox checked={lease.gate_access_remote} name="gate_access_remote" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Remote Control</Label>
            </div>
            <div className="d-flex ml-2">
              <Checkbox checked={lease.gate_access_card} name="gate_access_card" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Card Access</Label>
            </div>
            <div className="d-flex ml-2">
              <Checkbox checked={lease.gate_access_code} name="gate_access_code" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Code Access</Label>
            </div>
            <div className="d-flex ml-2">
              <Checkbox checked={lease.lost_remote_fee} name="lost_remote_fee" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Lost Remote Fee</Label>
            </div>
            <div className="d-flex ml-2">
              <Checkbox checked={lease.lost_card_fee} name="lost_card_fee" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Lost Card Fee</Label>
            </div>
            <div className="d-flex ml-2">
              <Checkbox checked={lease.code_change_fee} name="code_change_fee" onChange={this.change.bind(this)}/>
              <Label className="nowrap ml-2 mb-0">Code Change Fee</Label>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>;
  }
}

export default Gate;