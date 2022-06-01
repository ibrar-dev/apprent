import React from "react";

class EditableField extends React.Component {
  state = {};

  toggleEditMode() {
    const {editMode, value} = this.state;
    if (editMode && value) this.props.onSave(value);
    this.setState({...this.state, editMode: !editMode});
  }

  change(e) {
    this.setState({...this.state, value: e.target.value});
  }

  render() {
    const {editMode} = this.state;
    return <React.Fragment>
      <span className="input-group">
        <a onClick={this.toggleEditMode.bind(this)}
           style={{minWidth: 0}}
           className="input-group-addon bg-transparent border-0 p-1">
          <i className={`fas fa-${editMode ? 'save' : 'edit'}`}/>
        </a>
        <input className={editMode ? 'w-75' : 'border-0 bg-transparent w-75'}
               defaultValue={this.props.value}
               onChange={this.change.bind(this)}
               disabled={!editMode}/>
      </span>
    </React.Fragment>
  }
}

export default EditableField;