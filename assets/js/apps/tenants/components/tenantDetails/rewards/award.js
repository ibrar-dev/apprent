import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';
import actions from "../../../actions";

class Award extends React.Component {
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
    const {award} = this.props;
    return <tr  className="link-row" onMouseEnter={this.toggleOn.bind(this)}  onMouseLeave={this.toggleOff.bind(this)}>
      <td className="align-middle">
        {award.amount}
      </td>
      <td className="align-middle">
        {award.reason}
      </td>
      <td className="align-middle">
        {award.created_by}
      </td>
      <td className="align-middle">
        {award.inserted_at.slice(0,10)}
      </td>
      <td className="align-middle">
        {showDelete ? <i style={{color:"red"}} onClick={this.delete.bind(this)} className="far fa-trash-alt"></i> : <i style={{opacity:0}} className="far fa-trash-alt"></i>}
      </td>
    </tr>
  }
}

export default Award;