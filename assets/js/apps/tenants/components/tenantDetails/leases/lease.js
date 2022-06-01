import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Table, Button, Input, Card, CardBody, CardHeader} from 'reactstrap';
import {Modal, ModalBody, ModalHeader, ModalFooter} from 'reactstrap';
import DatePicker from '../../../../../components/datePicker';
import moment from 'moment';
import Charges from './leaseCharges';
import actions from "../../../actions";
import confirmationModal from '../../../../../components/confirmationModal';
import Select from '../../../../../components/select';
import canEdit from '../../../../../components/canEdit';
import confirmation from '../../../../../components/confirmationModal';

const picker = (name, value, handleChange, options = {clearable: true, customInputIcon: 'today'}) =>
  <DatePicker value={value} name={name} onChange={handleChange}{...options}/>;

const afterToday = (date) => date.isAfter(moment().endOf('day'));

class Lease extends React.Component {

  state = {lease: {...this.props.lease}, editMode: false, activeActionComponents: []};

  componentWillReceiveProps(nextProps, nextContext) {
    this.setState({lease: {...nextProps.lease}});
  }

  editMode() {
    this.setState({editMode: true, activeActionComponents: []});
  }

  changeDate({target: {name, value}}) {
    const {lease} = this.state;
    if (name === 'notice_date' && value && moment.duration(moment(this.props.lease.end_date).diff(moment(value))).asDays() < tenant.property.notice_period) {
      {
        confirmationModal("The date provided by the tenant violates the lease by not giving enough notice.").then(() => {
          this.setState({lease: {...lease, [name]: value.format('YYYY-MM-DD')}});
        });
      }
    } else if (!lease.move_out_date && name === "actual_move_out") {
      let date = value ? moment(value._d).format('YYYY-MM-DD') : value;
      this.setState({lease: {...this.state.lease, actual_move_out: date, move_out_date: date}});
    } else {
      this.setState({lease: {...this.state.lease, [name]: value ? moment(value._d).format('YYYY-MM-DD') : value}});
    }
  }

  fields(name) {
    const changeDate = this.changeDate.bind(this);
    const {lease} = this.state;
    const datePicker = {
      start_date: picker('start_date', lease.start_date, changeDate, {clearable: true}),
      end_date: picker('end_date', lease.end_date, changeDate, {})
    };
    return (datePicker[name])
  };

  save() {
    actions.updateLease(this.state.lease).catch(r => {
      confirmationModal(r.response.data.error, {header: 'Error', noCancel: true});
    });
    this.setState({editMode: false, activeActionComponents: []});
  }

  change({target: {name, value}}) {
    this.setState({lease: {...this.state.lease, [name]: value}});
  }

  toggleClose() {
    this.setState({editMode: false, activeActionComponents: [], lease: {...this.props.lease}});
  }

  cancelPending() {
    confirmationModal("Click okay to remove the Bluemoon id. Please only do this if the Bluemoon lease has expired.").then(() => {
      const {lease} = this.state;
      actions.updateLease({pending_bluemoon_lease_id: null, id: lease.id, pending_bluemoon_signature_id: null})
    });
  }

  actionButtons() {
    const {lease} = this.props;
    const buttons = [];
    if (!lease.actual_move_out && !lease.eviction && !lease.pending_bluemoon_lease_id && !lease.renewal && !lease.no_renewal) {
      buttons.push(<a className="btn btn-outline-success" target="_blank" href={`/leases/${lease.id}/new`}>
        Renewal
      </a>)
    }
    if (lease.pending_bluemoon_lease_id && !lease.renewal && !lease.no_renewal) {
      buttons.push(<Button color="secondary" outline
                           onClick={canEdit(["Super Admin", "Regional"]) ? this.cancelPending.bind(this) : null}>
        Transfer / Renewal Pending
      </Button>)
    }

    if (canEdit(['Super Admin'])) buttons.push(<Button color="info" outline
                                                     onClick={this.editMode.bind(this)}>Edit</Button>);
    return buttons.map((action, index) => <div key={index} className="mx-2">{action}</div>);
  }

  actionComponents() {
    let message = {
      actual_move_in: "Move In Date",
      notice_date: "Date Notice Was Given",
      move_out_date: "Expected Move Out Date",
      move_out_reason_id: "Move Out Reason"
    };
    const cards = this.state.activeActionComponents.map((component, i) => {
      return <Col lg={4} key={i}>
        <Card className="shadow-sm text-center m-0">
          <CardHeader>{message[component]}</CardHeader>
          <CardBody>
            {this.fields(component)}
          </CardBody>
        </Card>
      </Col>
    });
    return <Row>{cards}</Row>;
  }

  moveOutReason() {
    return this.props.moveOutReasons.find((option) => {
      return option.id === this.props.lease.move_out_reason_id
    });
  }

  disableButton() {
    const {lease, activeActionComponents} = this.state;
    return activeActionComponents.some(c => !lease[c]);
  }

  deleteLease() {
    confirmation('Really delete this lease?').then(() => {
      actions.deleteLease(this.props.lease.id);
    });
  }

  render() {
    const {lease, activeActionComponents} = this.state;
    const editMode = this.state.editMode;
    const {tenant} = this.props;
    const propLease = this.props.lease;
    return <div>
      <Row style={{backgroundColor: '#f7f9fc', margin: '20px 2px', boxShadow: '0 1px 4px rgba(0, 0, 0, 0.3)'}}>
        <Col xl={6} lg={12}>
          <Table borderless className="m-0">
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">
                Tenant(s)
              </th>
              <td className="nowrap align-middle border-0" style={{padding: '0.5rem 0.75rem'}}>
                <div className="d-flex">
                  <div>{tenant.first_name} {tenant.last_name}</div>
                  {tenant.other_tenants.map(t => {
                    if (tenant.id === t.id) return null;
                    return <React.Fragment key={t.id}>
                      <span>, </span>
                      <a className="text-info ml-2" href={`/tenants/${t.tenancy_id}`}>{t.first_name} {t.last_name}</a>
                    </React.Fragment>;
                  })}
                </div>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Lease Start
              </th>
              <td className="nowrap align-middle">
                {editMode ? this.fields('start_date') : propLease.start_date || "  - -"}
              </td>
            </tr>
            {/*<tr>*/}
            {/*  <th className="nowrap align-middle">*/}
            {/*    Deposit Amount*/}
            {/*  </th>*/}
            {/*  <td className="d-flex">*/}
            {/*    {editMode ? <Input name="deposit_amount"*/}
            {/*                       disabled={!editMode}*/}
            {/*                       type="number"*/}
            {/*                       value={lease.deposit_amount || ''}*/}
            {/*                       placeholder="Deposit Amount"*/}
            {/*                       onChange={change}/> : occ.deposit_amount || "  - -"}*/}
            {/*  </td>*/}
            {/*</tr>*/}
            {/*<tr>*/}
            {/*  <th className="nowrap align-middle">*/}
            {/*    Renewal*/}
            {/*  </th>*/}
            {/*  <td className="d-flex">*/}
            {/*    {editMode ? <Input disabled={true}*/}
            {/*                       value={(occ.renewal && occ.renewal.start_date) || ' - -'}/> : (occ.renewal && occ.renewal.start_date) || ' - -'}*/}
            {/*  </td>*/}
            {/*</tr>*/}
            </tbody>
          </Table>
        </Col>
        <Col xl={6} lg={12}>
          <Table borderless className="m-0">
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">
                Unit
              </th>
              <td className="border-0 nowrap align-middle">
                <a href={`/units/${tenant.unit.id}`}>{tenant.property.name} {tenant.unit.number}</a>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Lease End
              </th>
              <td>
                {editMode ? this.fields('end_date') : propLease.end_date || "  - -"}
              </td>
            </tr>
            </tbody>
          </Table>
        </Col>
        {editMode && <Col className="m-3 d-flex justify-content-end">
          <Button outline onClick={this.toggleClose.bind(this)}>Cancel</Button>
          <Button color="success" onClick={this.save.bind(this)} className="ml-2">
            <i className="fas fa-check"/> Save
          </Button>
        </Col>}
      </Row>
      <div className="d-flex justify-content-between" style={{marginLeft: -8}}>
        <div className="d-flex">{this.actionButtons()}</div>
        <div>
          <Button onClick={this.deleteLease.bind(this)} color="danger">
            <i className="fas fa-times"/> Delete Lease
          </Button>
        </div>
      </div>
      <div className="mt-3">
        <Charges lease={lease} charges={lease.charges}/>
      </div>
      <Modal isOpen={activeActionComponents.length > 0} toggle={this.toggleClose.bind(this)} size="lg">
        <ModalHeader toggle={this.toggleClose.bind(this)}>Edit</ModalHeader>
        <ModalBody>
          {this.actionComponents()}
        </ModalBody>
        <ModalFooter>
          <Button outline color="success" disabled={this.disableButton()} onClick={this.save.bind(this)}
                  style={{boxShadow: '0 1px 4px rgba(0, 0, 0, 0.3)'}}>
            <i className="fas fa-check"/> Save
          </Button>
        </ModalFooter>
      </Modal>
    </div>;
  }
}

export default connect(({moveOutReasons}) => {
  return {moveOutReasons};
})(Lease);
