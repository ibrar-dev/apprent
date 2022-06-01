import React from 'react';
import moment from 'moment';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Row, Col, ButtonGroup} from 'reactstrap';
import DatePicker from '../../../../../components/datePicker';
import MonthPicker from '../../../../../components/datePicker/monthPicker';
import actions from "../../../actions";
import confirmation from "../../../../../components/confirmationModal";

class EditCharge extends React.Component {
  state = {...this.props.charge, date: moment(), mode: 'edit'};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  reverse() {
    const {toggle, charge} = this.props;
    const {date, post_month} = this.state;
    confirmation('Reverse this charge?').then(() => {
      actions.deleteCharge({id: charge.id, reversalDate: date.format('YYYY-MM-DD'), post_month: moment(post_month).format('YYYY-MM-DD')}).then(toggle);
    });
  }

  save() {
    const {toggle, charge} = this.props;
    const {post_month} = this.state;
    actions.updateCharge({id: charge.id, post_month}).then(toggle);
  }

  changeMode(mode) {
    this.setState({mode});
  }

  render() {
    const {toggle} = this.props;
    const {date, mode, post_month} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Edit Charge
      </ModalHeader>
      <ModalBody>
        <ButtonGroup>
          <Button color="info" outline={mode !== 'edit'} onClick={this.changeMode.bind(this, 'edit')}>
            Edit
          </Button>
          <Button color="info" outline={mode !== 'reverse'} onClick={this.changeMode.bind(this, 'reverse')}>
            Reverse
          </Button>
        </ButtonGroup>
        {mode === 'edit' && <Row className="d-flex align-items-center">
          <Col sm={4}>
            Post Month
          </Col>
          <Col sm={8}>
            <MonthPicker month={moment(post_month)} onChange={this.change.bind(this)} name="post_month"/>
          </Col>
        </Row>}
        {mode === 'reverse' && <Row className="d-flex align-items-center mb-3">
          <Col sm={4}>
            Post Month
          </Col>
          <Col sm={8}>
            <MonthPicker month={moment(post_month)} onChange={this.change.bind(this)} name="post_month"/>
          </Col>
        </Row>}
        {mode === 'reverse' && <Row className="d-flex align-items-center">
          <Col sm={4}>
            Reversed On:
          </Col>
          <Col sm={8}>
            <DatePicker value={date} onChange={this.change.bind(this)} name="date"/>
          </Col>
        </Row>}
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>Cancel</Button>
        {mode === 'reverse' && <Button color="success" onClick={this.reverse.bind(this)}>Reverse</Button>}
        {mode === 'edit' && <Button color="success" onClick={this.save.bind(this)}>Save</Button>}
      </ModalFooter>
    </Modal>
  }
}

export default EditCharge;
