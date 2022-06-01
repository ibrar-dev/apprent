import React from 'react';
import {Input, Modal, ModalHeader, ModalBody, ModalFooter, Button, Col, Row, Badge} from "reactstrap";
import moment from 'moment';
import Uploader from '../../../../components/uploader';
import Select from '../../../../components/select';
import RadioButtons from '../../../../components/radioButtons';
import {titleize} from "../../../../utils";
import snackbar from "../../../../components/snackbar";
import CheckDetails from './checkDetails';
import Receipt from './receipt';

class NewPaymentModal extends React.Component {
  state = {
    mode: this.props.item && this.props.item.mode ? this.props.item.mode : 'tenant',
    amount: this.props.item && this.props.item.amount,
    transactionId: this.props.item && this.props.item.transaction_id,
    paymentType: this.props.item && this.props.item.payment_type,
    image: this.props.item && this.props.item.image,
    payerValue: this.props.item && this.props.item.payer_value,
    payerName: this.props.item && this.props.item.payer,
    receipts: this.props.item && this.props.item.receipts ? this.props.item.receipts : [{amount: 0, id: 1}],
    memo: this.props.item && this.props.item.memo,
    lease_id: this.props.item && this.props.item.lease_id
  };

  addPayment() {
    const {parent, property, toggle, item} = this.props;
    const {amount, transactionId, paymentType, image, mode, payerValue, payerName, receipts, memo, lease_id} = this.state;
    const params = {
      property_id: property.id,
      description: paymentType,
      transaction_id: transactionId,
      payer: payerName,
      payer_value: payerValue,
      payment_type: paymentType,
      amount: parseFloat(amount),
      mode,
      lease_id,
      image,
      memo
    };
    mode.toLowerCase().includes("tenant") ? params["tenant_id"] = payerValue : params[`${mode}_id`] = payerValue;
    params[`${mode}_id`] = payerValue;
    if (mode !== 'tenant') params.receipts = receipts;
    item ? parent.editPayment(params, item) : parent.newPayment(params);
    toggle();
  }

  change({target: {name, value}}) {
    name === 'mode' ?
      this.setState({[name]: value, payerValue: null, payerName: null, lease_id: null})
      :
      this.setState({[name]: value})
  }

  changeAttachment(image) {
    this.setState({image});
  }

  canAddOrDeposit() {
    const {tenants} = this.props;
    const {amount, transactionId, paymentType, image, payerValue, lease_id, mode} = this.state;
    const leasesMoreThanOne = payerValue && mode !== "application" && mode !== "np" && tenants.find(x => x.id === payerValue).leases.length > 1;
    if (parseFloat(amount) > 0 && (transactionId && transactionId.length > 3) && paymentType && payerValue && (image && image.fileType) && ((leasesMoreThanOne && lease_id) || (!leasesMoreThanOne))) return this.addPayment();
    if (!amount || parseFloat(amount) < 0) {
      return snackbar({
        message: 'Payment Amount Must Be Greater Than 0',
        args: {type: 'error'}
      })
    } else if (!transactionId || transactionId.length <= 3) {
      return snackbar({
        message: 'Check or Money Order number must be longer than 3 digits',
        args: {type: 'error'}
      })
    } else if (!paymentType) {
      return snackbar({
        message: 'Please select check or money order',
        args: {type: 'error'}
      })
    } else if (!image || !image.fileType) {
      return snackbar({
        message: 'Please upload proof of payment',
        args: {type: 'error'}
      })
    } else if (!payerValue) {
      return snackbar({
        message: 'Please select payer',
        args: {type: 'error'}
      })
    } else if (!(leasesMoreThanOne && lease_id)) {
      return snackbar({
        message: 'Please select a lease',
        args: {type: 'error'}
      })
    }
  }

  changePayer({target: {value: payerValue}}) {
    const payerName = typeof payerValue === 'number' ? this.selectOptions().find(o => o.value === payerValue).name : payerValue;
    this.setState({payerValue: payerValue, payerName});
  }

  unitInfo(t) {
    if (t.unit) return `Unit - ${t.unit} `;
    if (t.move_in.unit) return `Unit - ${t.move_in.unit} `;
    return ""
  }

  selectOptions() {
    const {mode} = this.state;
    const {tenants, applicants} = this.props;
    switch (mode) {
      case 'tenant':
        return tenants.filter(x => x.leases.find(a => a.current_tenant)).map(t => {
          return {
            label: `${t.name} Unit(${t.leases[0].number})`,
            value: t.id,
            name: `${t.name} Unit(${t.leases[0].number})`
          }
        });
      case 'pastTenant':
        return tenants.filter(x => x.leases.find(a => !a.current_tenant)).map(t => {
          return {
            label: `${t.name} Unit(${t.leases[0].number})`,
            value: t.id,
            name: `${t.name} Unit(${t.leases[0].number})`
          }
        });
      case 'application':
        return applicants.map(t => {
          return {
            label: `${t.name} ${this.unitInfo(t)} - Status: ${titleize(t.status)} - Move In: ${moment(t.move_in.expected_move_in).format("MM/DD/YY")}`,
            value: t.id,
            name: t.name
          }
        });
      default:
        return null;
    }
  }

  addReceipt() {
    const {receipts} = this.state;
    receipts.push({amount: 0, id: receipts.reduce((m, r) => r.id > m ? r.id : m, 0) + 1});
    this.setState({receipts: [...receipts]});
  }

  removeReceipt({id}) {
    const {receipts} = this.state;
    this.setState({receipts: receipts.filter(r => r.id !== id)});
  }

  changeReceipt(receipt, change) {
    const {receipts} = this.state;
    this.setState({
      receipts: receipts.map(r => {
        if (r.id === receipt.id) return {...r, ...change};
        return r;
      })
    }, () => this.updateAmount());
  }

  updateAmount() {
    const {receipts} = this.state;
    this.setState({amount: receipts.reduce((acc, r) => acc + parseFloat(r.amount), 0.00)})
  }

  selectLease(leaseID) {
    this.setState({...this.state, lease_id: leaseID})
  }

  render() {
    const {toggle, property, tenants, item} = this.props;
    const {amount, transactionId, paymentType, image, payerValue, mode, payerName, receipts, memo, lease_id} = this.state;
    const selectOptions = this.selectOptions();
    const selectedTenant = mode !== "application" && mode !== "np" && payerValue && tenants.find(x => x.id === payerValue).leases;
    return <Modal size="lg" isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Add Payment</ModalHeader>
      <ModalBody>
        <div className="mb-3 d-flex align-items-center">
          <div className="mr-3">
            <RadioButtons options={[
              {label: 'Current', value: 'tenant'},
              {label: 'Past', value: 'pastTenant'},
              {label: 'Future', value: 'application'},
              {label: 'Non Payer', value: 'np'},
            ]} name="mode" value={mode} onChange={this.change.bind(this)}/>
          </div>
          <div className="flex-auto">
            {selectOptions && <Select value={payerValue}
                                      placeholder="Select Payer"
                                      onChange={this.changePayer.bind(this)}
                                      options={selectOptions}/>}
            {!selectOptions && <Input value={payerValue}
                                      placeholder="Payer Name"
                                      onChange={this.changePayer.bind(this)}/>}
          </div>
        </div>
        {selectedTenant && selectedTenant.length > 1 && <h6>Select Lease</h6>}
        <Row className="mb-3">
          {
            selectedTenant && selectedTenant.length > 1 && tenants.find(x => x.id === payerValue).leases.filter(l => !l.renewal_id).map(y => {
              return <Col sm={3}>
                <Row className="d-flex justify-content-center">
                  <small>Unit - {y.number}</small>
                </Row>
                <Badge className="d-flex align-items-center" color="success" onClick={this.selectLease.bind(this, y.id)}
                       style={lease_id === y.id ? {
                           backgroundColor: "#d4edda",
                           color: "#155724",
                           height: 22,
                           paddingLeft: 6,
                           paddingRight: 6,
                           cursor: "pointer",
                           border: "solid thin green"
                         }
                         : {
                           backgroundColor: "#d4edda",
                           color: "#155724",
                           height: 22,
                           paddingLeft: 6,
                           paddingRight: 6,
                           cursor: "pointer"
                         }}>
                  {y.start_date} to {y.end_date}
                </Badge>
              </Col>
            })
          }
        </Row>
        <div className="mb-3 d-flex align-items-center">
          <div className="mr-3">
            <RadioButtons options={[
              {label: 'Check', value: 'Check'},
              {label: 'Money Order', value: 'Money Order'}
            ]} name="paymentType" value={paymentType} onChange={this.change.bind(this)}/>
          </div>
          <div className="flex-auto">
            <Input value={transactionId || ''} name="transactionId" placeholder="Number"
                   onChange={this.change.bind(this)}/>
          </div>
        </div>
        <div className="mb-3 d-flex align-items-center">
          <div className="mr-3">
            <label className={`m-0 p-2 rounded-circle clickable bg-${image && image.filename ? 'success' : 'danger'}`}>
              <i className="fas fa-2x fa-camera text-white clickable"/>
              <Uploader hidden modal oldFile={image} onChange={this.changeAttachment.bind(this)}/>
            </label>
          </div>
          <div className="flex-auto">
            <Input value={mode !== "tenant" && mode !== 'pastTenant' ? null : amount}
                   disabled={mode !== "tenant" && mode !== 'pastTenant'} placeholder="Amount" name="amount"
                   onChange={this.change.bind(this)}/>
          </div>
          {(mode !== 'tenant' && mode !== 'pastTenant') && <div className="ml-3">
            <Button color="success" onClick={this.addReceipt.bind(this)}>Add Line</Button>
          </div>}
        </div>
        <div className="mb-3">
          {mode !== 'tenant' && mode !== 'pastTenant' && receipts.map(r => <Receipt key={r.id}
                                                                                    receipt={r}
                                                                                    onChange={this.changeReceipt.bind(this)}
                                                                                    removeReceipt={this.removeReceipt.bind(this, r)}
                                                                                    removable={receipts.length > 1}/>)}
        </div>
        <div className="mb-3">
          <Input value={memo || ''} placeholder="Memo" name="memo" onChange={this.change.bind(this)}/>
        </div>
        <div>
          <CheckDetails property={property ? property.name : ''} memo={memo} number={transactionId} amount={amount}
                        name={payerName}/>
        </div>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.canAddOrDeposit.bind(this)}>
          {item ? "Edit Deposit" : "Add To Batch"}
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewPaymentModal;