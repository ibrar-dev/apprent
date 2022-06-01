import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button} from 'reactstrap';
import Select from '../../../../../components/select';
import QuerySelect from '../../../../../components/select/querySelect';
import actions from '../../../actions';
import NSFPayment from './nsfPayment';
import Uploader from '../../../../../components/uploader';
import MonthPicker from '../../../../../components/datePicker/monthPicker';
import axios from 'axios'

const paymentTypes = [
  {label: 'AppRent Payment', value: 'AppRent Payment'},
  {label: 'Opening Balance', value: 'Opening Balance'},
  {label: 'Check', value: 'Check'},
  {label: 'Money Order', value: 'Money Order'}
];

const paymentStatus = [
  {label: 'Pending', value: 'pending'},
  {label: 'Cleared', value: 'cleared'},
  {label: 'Failed', value: 'failed'}
];

class EditPayment extends React.Component {
  state = {...this.props.payment, leases: []};

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  changeTenant({target: {name, value}}) {
    const getLease = () => {
      axios.get('/api/tenants/' + value).then(r => {
        this.setState({availableLeases: r.data.leases})
      })
    }
    this.setState({...this.state, [name]: value}, () => getLease());
  }

  changeAttachment(image) {
    this.setState({...this.state, image});
  }

  save() {
    const {toggle, tenant} = this.props;
    const {inserted_at, lease_id, tenant_id, post_month} = this.state;
    const params = {
      ...this.state,
      lease_id: lease_id,
      tenant_id: tenant_id || tenant.id,
      post_month: post_month.format ? post_month.format('YYYY-MM-DD') : post_month,
      inserted_at: inserted_at.format ? inserted_at.format() : inserted_at
    };
    params.image.upload().then(() => {
      params.image.uuid ? params.image = {uuid: params.image.uuid} : delete params.image;
      actions.updatePayment(params).then(toggle);
    });

  }

  toggleNSF(close) {
    this.setState({...this.state, nsfModal: !this.state.nsfModal});
    if (close === 'close') this.props.toggle();
  }

  search(name) {
    const {payment: {property_id}} = this.props;
    return actions.searchTenants(name, property_id)
  }

  render() {
    const {toggle, payment, tenant} = this.props;
    const canEdit = payment.status !== 'voided' && !payment.nsf_id && payment.source === 'admin';
    const {description, amount, transaction_id, status, nsfModal, tenant_id, post_month} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      {nsfModal && <NSFPayment tenant={tenant} payment={payment} toggle={this.toggleNSF.bind(this)}/>}
      <ModalHeader toggle={toggle}>
        Edit Payment
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Post Month
          </Col>
          <Col sm={9}>
            <MonthPicker onChange={this.change.bind(this)} month={moment(post_month)} name="post_month"/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex flex-column justify-content-center">
            Tenant
            <small style={{opacity: 0}}>t</small>
          </Col>
          <Col sm={9}>
            <div style={{marginBottom: -5}}>
              <QuerySelect value={tenant_id || tenant.id}
                           disabled={!canEdit}
                           search={this.search.bind(this)}
                           defaultOptions={[{label: `${tenant.first_name} ${tenant.last_name}`, value: tenant.id}]}
                           transform={r => r.data.map(t => {
                             return {label: `${t.name}(${t.property} Unit ${t.unit})`, value: t.id};
                           })}
                           onChange={this.changeTenant.bind(this)}
                           name="tenant_id"/>
            </div>
            <small className="text-danger" style={{marginLeft: 1}}>Enter a tenant name(minimum 3 characters)</small>
          </Col>
        </Row>
        {this.state.availableLeases &&
          <Row className="mb-3">
            <Col sm={3} className="d-flex flex-column justify-content-center">Lease</Col>
            <Col sm={9}>
              <div style={{marginBottom: -5}}>
              <Select
                name="lease_id"
                value={this.state.lease_id}
                onChange={this.change.bind(this)}
                options={this.state.availableLeases.map(l => { return {label: `${l.start_date} - ${l.end_date}`, value: l.id} })}
                />
            </div>
            </Col>
          </Row>
        }
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Description
          </Col>
          <Col sm={9}>
            <Select value={description} name="description" disabled={!canEdit}
                    onChange={this.change.bind(this)} options={paymentTypes}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            ID Number
          </Col>
          <Col sm={9}>
            <Input disabled={!canEdit} value={transaction_id || ''} name="transaction_id"
                   onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Amount
          </Col>
          <Col sm={9}>
            <Input disabled={!canEdit} type="number" value={amount || ''} name="amount"
                   onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Status
          </Col>
          <Col sm={9}>
            {payment.nsf_id && <Select value='nsf' disabled name="status" options={[{label: 'NSF', value: 'nsf'}]}/>}
            {payment.status === 'voided' &&
            <Select value='voided' disabled name="status" options={[{label: 'Voided', value: 'voided'}]}/>}
            {!payment.nsf_id && payment.status !== 'voided' && <Select value={status} name="status"
                                                                       onChange={this.change.bind(this)}
                                                                       options={paymentStatus}/>}
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Image
          </Col>
          <Col sm={9}>
            <Uploader disabled={!!payment.nsf_id} onChange={this.changeAttachment.bind(this)}/>
          </Col>
        </Row>
        <div className="d-flex justify-content-between">
          <Button disabled={!!payment.nsf_id} color="danger" onClick={this.toggleNSF.bind(this)}>Mark NSF</Button>
          <Button className="w-50" color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </div>
      </ModalBody>
    </Modal>;
  }
}

export default connect(({tenant, accounts, batchIDS}) => {
  return {tenant, accounts, batchIDS};
})(EditPayment);
