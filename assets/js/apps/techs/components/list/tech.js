import React from 'react';
import {connect} from 'react-redux';
import {Col} from "reactstrap";
import EditTech from './editTech';
import ShowTech from "./showTech";

class Tech extends React.Component {
  state = {};

  toggleEdit() {
    this.setState({...this.state, edit: !this.state.edit});
  }

  render() {
    const {tech, properties, categories} = this.props;
    const {edit} = this.state;
    const toggle = this.toggleEdit.bind(this);
    const props = {tech, properties, toggle, categories};
    return (
      <Col md={6}>
        {edit ? <EditTech {...props}/> : <ShowTech {...props}/>}
      </Col>
    )
  }
}

export default connect(({properties, categories}) => {
  return {properties, categories};
})(Tech);
