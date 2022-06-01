import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';
import actions from "../../../actions";

class ExpiredLease extends React.Component {
  state = {showDelete:false}
  toggleOn(){
    this.setState({...this.state, showDelete: true})
  }
  toggleOff(){
    this.setState({...this.state, showDelete: false})
  }
  delete(){
    confirm("Are you sure you want to delete this award?")
    {
      actions.deleteAward(this.props.award.id, this.props.award.tenant_id)
    }
  }

  rentAmount() {
    const {lease} = this.props;
    if (!lease.charges || !lease.charges.length) return "N/A";
    console.log(lease.charges)
    return lease.charges.filter(c => c.name === "Rent" || c.name === "HAPRent").reduce((acc, c) => {
      return acc + c.amount
    }, 0)
  }

  render() {
    const {showDelete} = this.state;
    const {lease} = this.props;
    return <tr  className="link-row"  >
      <td className="align-middle">
        {lease.tenant.name}
      </td>
      <td className="align-middle">
      {lease.unit.property.name}
      </td>
      <td className="align-middle">
        {lease.unit.number}
      </td>
      <td className="align-middle">
        {lease.unit.floor_plan}
      </td>
      <td className="align-middle">
        ${this.rentAmount()}
      </td>
      <td className="align-middle">
        {lease.end_date}
      </td>
    </tr>
  }
}

export default ExpiredLease;