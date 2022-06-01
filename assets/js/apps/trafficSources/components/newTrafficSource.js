import React from 'react';
import {Modal, ModalHeader, ModalBody, Input, Button, Row, Col} from 'reactstrap';
import actions from "../actions";

class NewTrafficSource extends React.Component {
  state = {source: {name: '', type: ''}};

  change({target: {name, value}}) {
    this.setState({...this.state, source: {...this.state.source, [name]: value}});
  }

  save() {
    actions.createTrafficSource(this.state.source).then(this.props.toggle);
  }

  render() {
    const {source} = this.state;
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Traffic Source
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm={3}>
            Name
          </Col>
          <Col>
            <div className="input-group">
              <label>Name</label>
              <Input name="name" value={source.name} onChange={this.change.bind(this)} />
            </div>
          </Col>
          <Col>
            <div className="input-group">
              <label>Type</label>
              <Input type="select" name="type" value={source.type} onChange={this.change.bind(this)}>
                <option value="call">Call</option>
                <option value="walk_in">Walk In</option>
                <option value="email">Email</option>
                <option value="other">Other</option>
                <option value="sms">SMS</option>
                <option value="web">Web</option>
                <option value="chat">Chat</option>
              </Input>
            </div>
          </Col>
        </Row>
        <Row className="mt-3">
          <Col sm={{size: 9, offset: 3}}>
            <Button color="success" block={true} onClick={this.save.bind(this)}>
              Create
            </Button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>;
  }
}

export default NewTrafficSource;