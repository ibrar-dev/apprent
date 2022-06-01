import React from 'react';
import actions from '../actions';

class ArgField extends React.Component {
  state = {value: this.props.value};

  change(e) {
    this.setState({value: e.target.value});
  }

  toggleEdit() {
    this.setState({edit: !this.state.edit});
  }

  handleKey(e) {
    if (e.which === 13) {
      this.props.onChange(this.state.value);
      this.setState({edit: !this.state.edit});
    }
  }

  render() {
    const {edit, value} = this.state;
    return edit ? <input value={value} onKeyDown={this.handleKey.bind(this)} onChange={this.change.bind(this)}/> :
      <a onClick={this.toggleEdit.bind(this)}>{value}</a>;
  }
}

class Migration extends React.Component {

  changeArg(index, value) {
    const {migration} = this.props;
    migration.arguments[index] = value;
    actions.updateMigration(migration);
  }

  deleteArg(index) {
    const {migration} = this.props;
    migration.arguments.splice(index, 1);
    actions.updateMigration(migration);
  }

  addArg() {
    const {migration} = this.props;
    migration.arguments.push(0);
    actions.updateMigration(migration);
  }

  deleteMigration() {
    if (confirm('Delete this migration?')) {
      actions.deleteJob(this.props.migration);
    }
  }

  render() {
    const {migration} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteMigration.bind(this)}>
          <i className="fas fa-times text-danger" />
        </a>
      </td>
      <td>{migration.module}</td>
      <td>{migration.function}</td>
      <td>
        <ul className="list-unstyled">
          {migration.arguments.map((a, i) => <li key={i}>
            <a onClick={this.deleteArg.bind(this, i)}>
              <i className="fas fa-times text-danger"/>
            </a>
            {' '}
            <ArgField value={a} onChange={this.changeArg.bind(this, i)} />
          </li>)}
        </ul>
        <a onClick={this.addArg.bind(this)}>New</a>
      </td>
    </tr>;
  }
}

export default Migration