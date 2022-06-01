import React from 'react';
import EditableField from '../editableField';
import confirmation from "../../../../components/confirmationModal";
import actions from "../../actions";

class Bank extends React.Component {
  deleteDamage() {
    confirmation('Delete this bank?').then(() => {
      actions.deleteBank(this.props.bank);
    });
  }

  update(field, value) {
    actions.updateBank({...this.props.bank, [field]: value});
  }

  render() {
    const {bank} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteDamage.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td className="p-1">
        <EditableField value={bank.routing} onSave={this.update.bind(this, 'routing')}/>
      </td>
      <td className="p-1">
        <EditableField value={bank.name} onSave={this.update.bind(this, 'name')}/>
      </td>
    </tr>
  }
}

export default Bank;