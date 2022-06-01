import React from 'react';
import {connect} from 'react-redux';
import EditableField from '../editableField';
import confirmation from '../../../../components/confirmationModal';
import Select from '../../../../components/select';
import actions from '../../actions';

class Damage extends React.Component {
  deleteDamage() {
    confirmation('Delete this damage type?').then(() => {
      actions.deleteDamage(this.props.damage);
    });
  }

  update(name) {
    actions.updateDamage({...this.props.damage, name});
  }

  changeAccount({target: {value}}) {
    actions.updateDamage({...this.props.damage, account_id: value});
  }

  render() {
    const {damage, accounts} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteDamage.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="p-1">
        <Select options={accounts.map(a => {
          return {label: a.name, value: a.id};
        })} value={damage.account_id} onChange={this.changeAccount.bind(this)} name="account_id"
        />
      </td>
      <td className="p-1">
        <EditableField value={damage.name} onSave={this.update.bind(this)}/>
      </td>
    </tr>
  }
}

export default connect(({accounts}) => {
  return {accounts};
})(Damage);