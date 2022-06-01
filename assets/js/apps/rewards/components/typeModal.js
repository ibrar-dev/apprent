import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Input, Row, Col} from 'reactstrap';
import Switch from 'react-switch';
import DropZone from '../../../components/dropzone';
import actions from '../actions';

class TypeModal extends React.Component {
  state = this.props.type;

  save() {
    const {id, name, icon, points, active, monthly_max} = this.state;
    actions.saveType({id, name, icon, points, active, monthly_max}).then(this.props.toggle);
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeIcon(file) {
    this.setState({icon: file});
  }

  toggleActive() {
    this.setState({active: !this.state.active});
  }

  render() {
    const {toggle} = this.props;
    const {id, name, active, icon, points, monthly_max} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        {id ? 'Edit' : 'New'} Category
      </ModalHeader>
      <ModalBody>
        <div className="d-flex">
          <div className="mr-3">
            <DropZone onChange={this.changeIcon.bind(this)} prompt={<i className="fas fa-question"/>}
                      image={icon} style={{width: 45, height: 45, borderRadius: '50%', border: '1px solid #e3e3e3'}}/>
          </div>
          <div className="labeled-box w-100">
            <Input className="form-control-lg" name="name" onChange={this.change.bind(this)} value={name || ''}/>
            <div className="labeled-box-label">Name</div>
          </div>
        </div>
        <Row className="mt-3">
          <Col sm={3} className="d-flex align-items-center justify-content-between">
            Active: <Switch onChange={this.toggleActive.bind(this)} checked={active}/>
          </Col>
          <Col sm={6}>
            <div className="labeled-box">
              <Input name="points" type="number" value={points} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Points</div>
            </div>
          </Col>
          <Col sm={3} className="d-flex align-items-center justify-content-between">
            <div className="labeled-box">
              <Input name="monthly_max" type="number" value={monthly_max} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Monthly Max</div>
            </div>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default TypeModal;