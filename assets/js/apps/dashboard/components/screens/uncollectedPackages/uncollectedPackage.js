import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';
import actions from "../../../actions";

class UncollectedPackage extends React.Component {
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
    const {packs} = this.props;
    return <tr  className="link-row"  >
      <td className="align-middle">
        {packs.name}
      </td>
      <td className="align-middle">
      {packs.property.name}
      </td>
      <td className="align-middle">
        {packs.unit.number}
      </td>
      <td className="align-middle">
        {packs.carrier}
      </td>
    </tr>
  }
}

export default UncollectedPackage;