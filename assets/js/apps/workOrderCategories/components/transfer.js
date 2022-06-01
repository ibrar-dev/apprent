import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button} from 'reactstrap';
import actions from '../actions';
import Select from '../../../components/select';

class Transfer extends React.Component {
  state = {};

  transfer() {
    const {toggle, fromCategory} = this.props;
    const {targetId} = this.state;
    actions.transfer(fromCategory.id, targetId).then(toggle);
  }

  changeTarget({target: {value}}) {
    this.setState({targetId: value});
  }

  render() {
    const {toggle, options, fromCategory} = this.props;
    const {targetId} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Transfer From {fromCategory.name}</ModalHeader>
      <ModalBody>
        <Select options={options} value={targetId} onChange={this.changeTarget.bind(this)}/>
      </ModalBody>
      <ModalFooter>
        <Button onClick={this.transfer.bind(this)} color="success">
          Transfer
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({categories}) => {
  const options = [];
  categories.forEach(c => {
    c.children.forEach(ch => options.push({value: ch.id, label: `${c.name} -- ${ch.name}`}));
  });
  return {options}
})(Transfer);