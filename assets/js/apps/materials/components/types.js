import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';

class Types extends React.Component {
  state = {newTypeName: '', selectedId: this.props.selected};

  addType() {
    this.setState({...this.state, addMode: true});
  }

  changeTypeName(e) {
    this.setState({...this.state, newTypeName: e.target.value});
  }

  keyDown(e) {
    if (e.which === 13) {
      actions.createType({name: this.state.newTypeName}).then(() => {
        this.setState({...this.state, newTypeName: '', addMode: null});
      });
    }
  }

  select(e) {
    this.props.onSelect(e);
    this.setState({...this.state, selectedId: e.target.value});
  }

  render() {
    const {addMode, newTypeName, selectedId} = this.state;
    const {types} = this.props;
    return <div className="d-flex">
      <select name="type_id"
              className="form-control"
              value={selectedId}
              onChange={this.select.bind(this)}>
        <option>Choose Type</option>
        {types.map(type => {
          return <option key={type.id} value={type.id}>
            {type.name}
          </option>;
        })}
      </select>
      <a className="ml-3 p-2 border" onClick={this.addType.bind(this)}>
        <i className="fas fa-plus text-success"/>
      </a>
      {addMode && <input className="ml-3 form-control"
                         onChange={this.changeTypeName.bind(this)}
                         onKeyDown={this.keyDown.bind(this)}
                         value={newTypeName}/>}
    </div>
  }
}

export default connect(({types}) => {
  return {types};
})(Types);