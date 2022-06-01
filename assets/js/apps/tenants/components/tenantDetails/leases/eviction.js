import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button} from 'reactstrap';
import DatePicker from '../../../../../components/datePicker';
import actions from '../../../actions';

class Eviction extends React.Component {
  state = {...this.props.eviction, file_date: this.props.eviction ? this.props.eviction.file_date : moment().format('YYYY-MM-DD')};

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value.startOf ? value.format('YYYY-MM-DD') : value});
  }

  save() {
    const {toggle, leaseId, eviction} = this.props;
    if (eviction && eviction.id) {
      actions.updateEviction(this.state).then(toggle);
    } else {
      actions.evict({...this.state, lease_id: leaseId}).then(toggle);
    }
  }

  deleteEviction() {
    const {toggle} = this.props;
    actions.deleteEviction(this.state).then(toggle);
  }

  render() {
    const {toggle} = this.props;
    const {file_date, court_date, charge_amount, notes, id} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Evict Tenant
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            File Date
          </Col>
          <Col sm={9}>
            <DatePicker value={file_date} name="file_date" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Court Date
          </Col>
          <Col sm={9}>
            <DatePicker value={court_date} name="court_date" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        {!id && <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Charge Amount
          </Col>
          <Col sm={9}>
            <Input value={charge_amount || ''} name="charge_amount" onChange={this.change.bind(this)}/>
          </Col>
        </Row>}
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Notes
          </Col>
          <Col sm={9}>
            <Input type="textarea" rows={4} value={notes || ''} name="notes" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <div className="d-flex justify-content-center">
          {id && <Button className="w-50 mr-4" color="danger" onClick={this.deleteEviction.bind(this)}>
            Delete Eviction
          </Button>}
          <Button className="w-50" color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </div>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({tenant, accounts}) => {
  return {tenant, accounts};
})(Eviction);