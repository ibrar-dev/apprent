import React from 'react';
import {Input} from 'reactstrap';

class EditableField extends React.Component {
  state = {value: this.props.value};

  toggleEdit() {
    this.setState({editMode: !this.state.editMode});
  }

  change({target: {value}}) {
    this.setState({value});
  }

  save(e) {
    if (e.keyCode === 13) {
      this.props.onSave(this.state.value);
      this.toggleEdit();
    }
  }

  render() {
    const {onSave, ...props} = this.props;
    const {editMode, value} = this.state;
    if (editMode) {
      return <Input {...props} value={value || ''} onChange={this.change.bind(this)} onKeyUp={this.save.bind(this)}/>
    }
    return <div onDoubleClick={this.toggleEdit.bind(this)}
                style={{background: '#f0f2f7'}}
                className="d-inline-block p-2 clickable rounded">
      {props.value}
    </div>;
  }
}

export default EditableField;