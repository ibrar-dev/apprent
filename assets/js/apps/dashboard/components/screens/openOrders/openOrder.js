import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';
import actions from "../../../actions";

class OpenOrder extends React.Component {
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


  render() {
    const {showDelete} = this.state;
    const {order} = this.props;
    return <tr  className="link-row"  >
      <td className="align-middle">
        {order.category}
      </td>
      <td className="align-middle">
      {order.property}
      </td>
      <td className="align-middle">
        {order.property}
      </td>
    </tr>
  }
}

export default OpenOrder;