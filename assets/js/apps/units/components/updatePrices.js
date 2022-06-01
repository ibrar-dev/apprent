import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Table, Input, ModalFooter} from 'reactstrap';
import {connect} from 'react-redux';
import {toCurr} from "../../../utils";
import actions from '../actions';

class UpdatePrices extends Component {
  constructor(props) {
    super(props);
    if (props.property) {
      this.state = {floorPlans: props.floorPlans.filter(f => f.property_id === props.property.id)};
    } else {
      this.state = {floorPlans: props.floorPlans}
    }
  }

  changeAmount(id, e) {
    const {floorPlans} = this.state;
    const floorPlan = floorPlans.filter(f => f.id === id)[0];
    floorPlan.amount = e.target.value;
    floorPlans.splice(floorPlans.indexOf(floorPlan), 1, floorPlan);
    this.setState({...this.state, floorPlans: floorPlans});
  }

  saveAmounts() {
    const {floorPlans} = this.state;
    const filtered = floorPlans.filter(f => f.amount && f.amount.length > 0);
    actions.updatePrices(filtered).then(this.props.toggle);
  }

  render() {
    const {toggle} = this.props;
    const {floorPlans} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Update Market Rent Pricing for Floor Plans</ModalHeader>
      <ModalBody>
        {floorPlans.length > 0 && <Table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Current Price</th>
              <th>New Price</th>
            </tr>
          </thead>
          <tbody>
          {floorPlans.map(f => {
            return <tr key={f.id}>
              <td>{f.name}</td>
              <td>{toCurr(f.mr_price || f.price)}</td>
              <td><Input type="number" value={f.amount} onChange={this.changeAmount.bind(this, f.id)} /></td>
            </tr>
          })}
          </tbody>
        </Table>}
        {!floorPlans.length && <div>No Floor Plans For This Property Yet</div>}
      </ModalBody>
      <ModalFooter>
        <div className="btn btn-outline-success" onClick={this.saveAmounts.bind(this)}>Save</div>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({floorPlans, property}) => {
  return {floorPlans, property}
})(UpdatePrices)
