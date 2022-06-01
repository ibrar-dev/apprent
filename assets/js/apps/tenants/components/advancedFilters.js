import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button, Row, Col} from 'reactstrap';
import Select from '../../../components/select';
import actions from '../actions';

class AdvancedFilters extends React.Component {

  clear() {
    actions.clearFilters();
    this.props.toggle();
  }

  render() {
    const {toggle, filters} = this.props;
    const {number} = filters;
    const change = ({target: {name, value}}) => actions.setFilters(name, value);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Advanced Filters</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box">
              <Input value={number || ''} onChange={change} name="number"/>
              <div className="labeled-box-label">Unit Number</div>
            </div>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter className="d-flex justify-content-between">
        <Button onClick={this.clear.bind(this)} color="success">
          Clear
        </Button>
        <Button onClick={toggle} color="success">
          OK
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({properties, filters}) => {
  return {properties, filters};
})(AdvancedFilters);