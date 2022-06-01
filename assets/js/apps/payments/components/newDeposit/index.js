import React from 'react';
import {connect} from "react-redux";
import {Card, CardHeader, CardBody, Row, Col, ListGroup, ListGroupItem, Button} from "reactstrap";
import moment from "moment";
import NewPaymentModal from './newPaymentModal';
import PropertySelect from '../../../../components/propertySelect';
import Select from '../../../../components/select';
import actions from '../../actions';
import {toCurr} from '../../../../utils';
import DatePicker from '../../../../components/datePicker';
import MonthPicker from '../../../../components/datePicker/monthPicker';
import confirmation from '../../../../components/confirmationModal';
import {withRouter} from "react-router-dom";

const canEdit = (role) => (
  window.roles.includes("Super Admin") || window.roles.includes(role)
);

class NewDeposit extends React.Component {
  state = {
    bankAccounts: [],
    tenants: [],
    items: [],
    applicants: [],
    postMonth: moment().startOf('month').add(10, 'hours')
  };

  setProperty(property) {
    actions.fetchBankAccounts(property.id).then(r => {
      const bank_account_id = r.data.length === 1 ? r.data[0].id : undefined;
      this.setState({bankAccounts: r.data, bank_account_id});
    });
    actions.fetchTenants(property.id).then(r => {
      this.setState({tenants: r.data, property});
    });
    actions.fetchApplicants(property.id).then(r => {
      this.setState({applicants: r.data, property});
    })
  }

  resetFields() {
    this.setState({items: []})
  }

  newPayment(params) {
    this.setState({items: this.state.items.concat(params)});
  }

  editPayment(params, oldItem) {
    const {items} = this.state;
    const index = items.findIndex(x => x.property_id == oldItem.property_id && x.transaction_id == oldItem.transaction_id && x.amount == oldItem.amount && x.lease_id == oldItem.lease_id)
    items.splice(index,1,params)
    this.setState({items: items.splice(index,1,params), item: null});
  }

  removeItem(index) {
    const {items} = this.state;
    items.splice(index, 1);
    this.setState({items});
  }

  setDepositDate(date) {
    this.setState({...this.state, depositDate: date})
  }

  changePostMonth({target: {name, value}}) {
    const firstOfMonth = moment.utc(value).startOf("month").add(10, 'hours');
    this.setState({...this.state, [name]: firstOfMonth});
  }

  saveDeposit() {
    const {property, items, depositDate, postMonth, bank_account_id} = this.state;
    const onSuccess = () => this.props.history.push('/payments')
    actions.createDeposit({
      property_id: property.id,
      inserted_at: depositDate.format(),
      post_month: postMonth,
      bank_account_id,
      items
    },
    onSuccess,
    )
  }

  confirmReset() {
    confirmation('Clear all deposits?').then(() => {
      this.resetFields();
    })
  }

  toggleNewPayment(item) {
    item && item.payer_value ?
        this.setState({newPayment: !this.state.newPayment, item: item})
        :
        this.setState({newPayment: !this.state.newPayment, item: null})
  }

  changeBankAccount({target: {value}}) {
    this.setState({bank_account_id: value});
  }

  render() {
    const {
      applicants,
      bankAccounts,
      bank_account_id,
      depositDate,
      item,
      items,
      newPayment,
      postMonth,
      property,
      tenants,
    } = this.state;
    let total = 0;
    return (
    <Card>
      <CardHeader className="p-0">
        <PropertySelect
          properties={properties}
          onChange={this.setProperty.bind(this)}
          property={property}
        />
      </CardHeader>
      <CardBody>
        <Row>
          <Col>
            <Row className="mb-3">
              <Col md={2} className="d-flex align-items-center">
                Deposit Date
              </Col>
              <Col className="d-flex">
                <div className="flex-auto">
                  <DatePicker value={depositDate || ""} onChange={this.setDepositDate.bind(this)}/>
                </div>
              </Col>
            </Row>
            <Row className="mb-3">
              <Col>
                <Row>
                  <Col md={4} className="d-flex align-items-center">
                    Post Month
                  </Col>
                  <Col>
                    <MonthPicker onChange={this.changePostMonth.bind(this)}
                                 options={{openDirection: 'up'}}
                                 month={moment(postMonth)}
                                 value={postMonth} name="postMonth"/>
                  </Col>
                </Row>
              </Col>
              <Col>
                {canEdit(["Super Admin", "Regional", "Accountant"]) && bankAccounts.length === 0 && <div className="h-100 d-flex align-items-center justify-content-center">
                  <a href={`/bank_accounts`} className="text-danger" target="_blank">
                    Please add a bank account for this property
                  </a>
                </div>}
                {canEdit(["Super Admin", "Regional", "Accountant"]) && bankAccounts.length > 0 && <Row>
                  <Col md={4} className="d-flex align-items-center">
                    Bank Account
                  </Col>
                  <Col>
                    <Select options={bankAccounts.map(b => {
                      return {label: b.name, value: b.id}
                    })} placeholder="Bank Account" value={bank_account_id}
                            onChange={this.changeBankAccount.bind(this)}/>
                  </Col>
                </Row>}
              </Col>
            </Row>
            <div className="d-flex mb-3">
              <Button color="success" onClick={this.toggleNewPayment.bind(this,null)}>
                <i className="fas fa-plus-circle"/> New Payment
              </Button>
              <div className="d-flex flex-auto justify-content-end">
                <Button color="danger" className="mr-3" onClick={this.confirmReset.bind(this)}>
                  <i className="fas fa-redo"/> Reset
                </Button>
                <Button disabled={items.length === 0 || !depositDate || (!bank_account_id && canEdit(["Super Admin", "Regional", "Accountant"]))} color="success"
                        onClick={this.saveDeposit.bind(this)}>
                  <i className="fas fa-check-circle"/> Create Deposit
                </Button>
              </div>
            </div>
          </Col>
          <Col>
            <ListGroup>
              {items.map((i, index) => {
                total += i.amount;
                return <ListGroupItem key={`${i.tenant_id}-${i.transaction_id}`}
                                      className="d-flex">
                  <Col sm={6}>
                    <a onClick={this.removeItem.bind(this, index)} className="mr-2">
                      <i className="fas fa-times text-danger"/>
                    </a>
                    {i.payer}
                  </Col>
                  <Col sm={3}>
                    {toCurr(i.amount)}
                  </Col>
                  <Col sm={3} className="d-flex justify-content-between ">{i.description} #{i.transaction_id}
                  <a onClick={this.toggleNewPayment.bind(this, i)} className="mr-2">
                    <i className="fas fa-pen"></i>
                  </a>
                  </Col>
                </ListGroupItem>
              })}
              <ListGroupItem className="d-flex">
                <Col>
                  <h3 className="m-0">
                    Total: {toCurr(total)}
                  </h3>
                </Col>
                <Col className="d-flex align-items-center m-0">
                  <Row className="d-flex  justify-content-between " style={{width:"100%"}}>
                    <Col className="d-flex align-items-center m-0">
                    <h6 className="m-0">
                      Check: {items.filter(x => x.description == "Check").length}
                    </h6>
                    </Col>
                    <Col className="d-flex align-items-center m-0">
                    <h6 className="m-0">
                      Money Order: {items.filter(x => x.description == "Money Order").length}
                    </h6>
                    </Col>
                  </Row>
                </Col>
              </ListGroupItem>
            </ListGroup>
          </Col>
        </Row>
      </CardBody>
      {newPayment && <NewPaymentModal tenants={tenants}
                                      parent={this}
                                      item={item}
                                      property={property}
                                      applicants={applicants}
                                      toggle={this.toggleNewPayment.bind(this)}/>}
    </Card>
    );
  }
}

export default withRouter(connect(({properties}) => ({properties}))(NewDeposit));
