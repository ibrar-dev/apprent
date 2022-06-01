import React from 'react';
import {connect} from 'react-redux';
import {Button, Modal, ModalHeader, ModalBody, Form, FormGroup, Label, Input} from 'reactstrap';
import actions from '../actions';
import Category from './category';

class Exports extends React.Component {
  state = {};

  render() {
    const {exports} = this.props;
    return <div>
      {exports.map(category => <Category category={category} key={category.id}/>)}
    </div>
  }
}

export default connect(({exports}) => ({exports}))(Exports);