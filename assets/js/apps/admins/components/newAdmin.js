import React from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col, Input, Button} from 'reactstrap';
import Select from '../../../components/select';
import actions from '../actions';

class NewAdmin extends React.Component {
  state = {name: '', email: '', username: '', password: '', roles: []};

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  changeRoles({target: {value: roles}}) {
    this.setState({...this.state, roles});
  }

  submit() {
    actions.saveAdmin(this.state).then(this.props.toggle);
  }

  render() {
    const {toggle} = this.props;
    const {name, email, username, roles, password} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Admin
      </ModalHeader>
      <ModalBody>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Name</b>
          </Col>
          <Col sm={9}>
            <Input name="name" value={name} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Username</b>
          </Col>
          <Col sm={9}>
            <Input name="username" value={username} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Email</b>
          </Col>
          <Col sm={9}>
            <Input name="email" value={email} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Password</b>
          </Col>
          <Col sm={9}>
            <Input name="password" value={password} onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            <b>Roles</b>
          </Col>
          <Col sm={9}>
            <Select value={roles}
                    multi={true}
                    options={['Super Admin', 'Admin', 'Accountant', 'Agent', 'Regional', 'Tech', 'Property'].map(r => {
                      return {value: r, label: r};
                    })}
                    onChange={this.changeRoles.bind(this)}/>
          </Col>
        </Row>
        <Button onClick={this.submit.bind(this)} color="success">
          Submit
        </Button>
      </ModalBody>
    </Modal>;
  }
}

export default NewAdmin;