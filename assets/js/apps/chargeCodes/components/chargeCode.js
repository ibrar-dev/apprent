import React from 'react';
import {Button} from 'reactstrap';

class ChargeCode extends React.Component {
  deleteCode() {

  }

  edit() {

  }

  render() {
    const {chargeCode} = this.props;
    return <tr>
      <td className="align-middle">{chargeCode.code}</td>
      <td className="nowrap align-middle">{chargeCode.name}</td>
      <td className="align-middle">{chargeCode.account_num}</td>
      <td className="nowrap align-middle">{chargeCode.account_name}</td>
      <td>
        <div className="d-flex">
        <Button className="mr-2" color="info" onClick={this.edit.bind(this)}>
          Edit
        </Button>
        <Button color="danger" onClick={this.deleteCode.bind(this)}>
          Delete
        </Button>
        </div>
      </td>
    </tr>
  }
}

export default ChargeCode;