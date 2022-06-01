import React from 'react';
import {Input, InputGroupAddon, InputGroup, Button} from 'reactstrap';


class Purchase extends React.Component {
  state = {account: this.props.account};

  componentWillReceiveProps(props) {
    this.setState({...this.state, account: props.account});
  }


  render() {
    const {account} = this.state;
    const {purchase} = this.props;
    return <tr  className="link-row">
      <td className="align-middle">
        {purchase.points}
      </td>
      <td className="align-middle">
        {purchase.reward.name}
      </td>
      <td className="align-middle">
        {purchase.inserted_at.slice(0,10)}
      </td>
      <td className="align-middle">
        {/* replace capitalizes the string */}
        {purchase.status.replace(/(^|\s)\S/g, l => l.toUpperCase())}
      </td>
    </tr>
  }
}

export default Purchase;
