import React from 'react';
import {connect} from 'react-redux';
import {Input} from 'reactstrap';
import Select from '../../../components/select';

class Charge extends React.Component {
  state = {};

  deleteCharge() {
    const {charge, onDelete} = this.props;
    onDelete(charge._id);
  }

  change({target: {name, value}}) {
    const newState = {...this.props.charge, [name]: value};
    const {charge, onChange} = this.props;
    onChange(charge._id, newState);
  }

  render() {
    const {charge, chargeCodes} = this.props;
    return <tr>
      <td className="align-middle text-center">
        <a onClick={this.deleteCharge.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="align-middle">
        <Select name="charge_code_id"
                value={charge.charge_code_id}
                options={chargeCodes.map(a => {
                  return {value: a.id, label: `${a.code} - ${a.name}`}
                })}
                onChange={this.change.bind(this)}/>
      </td>
      <td className="align-middle">
        <Input value={charge.amount || ''}
               type="number"
               name="amount"
               onChange={this.change.bind(this)}/>
      </td>
    </tr>;
  }
}

export default connect(({chargeCodes}) => {
  return {chargeCodes}
})(Charge);