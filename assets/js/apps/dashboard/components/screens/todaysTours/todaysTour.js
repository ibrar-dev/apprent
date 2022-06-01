import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';
import actions from "../../../actions";
import moment from 'moment';


class TodaysTour extends React.Component {
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
    const {tour} = this.props;
    return <tr  className="link-row"  >
      <td className="align-middle">
        {tour.prospect}
      </td>
      <td className="align-middle">
      {tour.property}
      </td>
      <td className="align-middle">
        {moment.utc().add(tour.start_time, 'minutes').format('LT')}
      </td>
    </tr>
  }
}

export default TodaysTour;