import React from 'react';

class EditableCell extends React.Component {

  state = {editing: false};

  componentWillReceiveProps(props) {
    this.setState({...this.state, stateValue: props.value});
  }

  change(e) {
    this.setState({...this.state, stateValue: e.target.value});
  }

  edit() {
    this.setState({...this.state, editing: true});
  }

  save(e) {
    if (e.which === 13) {
      this.props.onSave(this.state.stateValue).then(() => {
        this.setState({...this.state, editing: false});
      });
    }
  }

  render() {
    const {editing, stateValue} = this.state;
    const {value, type} = this.props;
    return <td onClick={this.edit.bind(this)}>
      {!editing && value}
      {editing && <input type={type || "text"}
                         value={stateValue || value}
                         className="form-control"
                         onKeyDown={this.save.bind(this)}
                         onChange={this.change.bind(this)} />}
    </td>;
  }
}

export default EditableCell;