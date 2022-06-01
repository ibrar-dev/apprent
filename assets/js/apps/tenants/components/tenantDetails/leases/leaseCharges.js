import React from 'react';
import {Button, Row, Col, Input} from 'reactstrap';
import moment from 'moment';
import LeaseChargesModal from './leaseChargesModal';
import {toCurr} from '../../../../../utils';
import Select from '../../../../../components/select';
import confirmation from '../../../../../components/confirmationModal';
import DatePicker from '../../../../../components/datePicker';
import canEdit from '../../../../../components/canEdit';
import {
  ValidatedDatePicker,
  validate,
  resetValidate
} from '../../../../../components/validationFields';

class LeaseCharge extends React.Component {
  state = {...this.props.charge};

  componentWillReceiveProps(props) {
    this.setState({...this.state, ...props.charge});
  }

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  changeType({target: {value}}) {
    const name = this.props.chargeCodes.filter(t => t.id === parseInt(value))[0].name;
    this.setState({...this.state, charge_code_id: value, name});
  }

  deleteCharge() {
    if(!this.state.id) return this.props.deleteCharge();
    if (confirm('Remove this monthly charge?')) {
      this.state.id ? actions.deleteLeaseCharge(this.state) : ''
    }
  }

  toggleEdit() {
    const {editMode: edit, ...charge} = this.state;
    const editMode = edit || !charge.id;
    resetValidate(this)
    this.setState({...this.props.charge, editMode: !editMode});
  }
  saveCharge(){
    validate(this).then(() => {
      actions.saveLeaseCharge(this.state);
      this.setState({...this.state, editMode: false});
    }).catch(() => {
    });
  }

  render() {
    const {chargeCodes, lease, index} = this.props;
    const {editMode: edit, ...charge} = this.state;
    const editMode = edit || !charge.id;
    const top = 145 + (index*79)
    return <tr style={{height:80}}>
      <td className="align-middle min-width">
        <a onClick={this.deleteCharge.bind(this)}>
          {canEdit('Super Admin') && <i className="fas fa-times text-danger"/>}
        </a>
      </td>
      <td>
        <Select value={charge.charge_code_id}
                styles={{
                  container(s) {
                    return {...s, pointerEvents: editMode ? '' : 'none'};
                  }
                }}
                options={chargeCodes.map(a => {
                  return {value: a.id, label: `${a.code} - ${a.name}`};
                })}
                onChange={this.changeType.bind(this)}
                name="account_id"/>
        {lease && !editMode && <div  className="d-flex" style={{position: "absolute", fontSize:"80%", top: top, color:"#939394"}}>
           This charge will begin on <h6 style={{fontSize:"100%", marginBottom:0, marginLeft:5, marginRight:5, color:"#5f5f63"}}>{(charge.from_date) ? moment.isMoment(charge.from_date) ? charge.from_date.format("YYYY-MM-DD"): charge.from_date : lease.start_date}</h6> and end on <h6 style={{fontSize:"100%", marginBottom:0, marginLeft:5, marginRight:1, color:"#5f5f63"}}>{(charge.to_date) ? moment.isMoment(charge.to_date) ? charge.to_date.format("YYYY-MM-DD"): charge.to_date : lease.end_date}</h6> , the next charge will be on <h6 style={{fontSize:"100%", marginBottom:0, marginLeft:5, marginRight:5, color:"#5f5f63"}}>{charge.next_bill_date}</h6>
        </div>}
      </td>
      <td>
        <Input value={charge.amount}
               disabled={!editMode}
               type="number"
               style={{height: 37}}
               onChange={this.change.bind(this)} name="amount"/>
      </td>
      <td>
        <ValidatedDatePicker value={charge.from_date} disabled={!editMode} clearable
                             onChange={this.change.bind(this)} name="from_date" feedback="Please select a date"
                             context={this} validation={(d) => true}
                             isOutsideRange={(x) => !!charge.to_date && (moment.isMoment(charge.to_date) ? charge.to_date < x : moment(charge.to_date) < x) }/>
      </td>
      <td>
        <ValidatedDatePicker value={charge.to_date} disabled={!editMode} clearable
                                  onChange={this.change.bind(this)} name="to_date" feedback="Please select a date"
                                  context={this} validation={(d) => true}
                                  isOutsideRange={(x) => !!charge.from_date && (moment.isMoment(charge.from_date) ? charge.from_date > x : moment(charge.from_date) > x)}/>
      </td>
      <td>
        {canEdit(["Super Admin", "Regional"]) && !editMode && <i className="far fa-edit fa-2x" onClick={this.toggleEdit.bind(this)} size="sm"/>}
        {editMode && [<i className="far fa-save fa-2x mr-2" key={'save'} onClick={this.saveCharge.bind(this)} size="sm"/>,
        <i className="far fa-window-close fa-2x" key={'cancel'} onClick={this.toggleEdit.bind(this)} size="sm"/>]}
          {/*<i className={`fas fa-${editMode ? 'save' : 'edit'} text-info`}/>*/}
      </td>
    </tr>
  }
}

// const Charge = connect(({accounts}) => {
//   return {accounts};
// })(LeaseCharge);

class LeaseCharges extends React.Component {
  state = {};

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen});
  }

  chargeExpired(c, end_date) {
    const today = moment().format("YYYY-MM-DD");
    if (!c.to_date && (today > end_date)) return true;
    if (c.to_date && (c.to_date < today)) return true;
    return false;
  }

  render() {
    const {modalOpen} = this.state;
    const {charges, lease} = this.props;
    return <div>
      <Row>
        <Col>
          <table>
            <thead>
            <tr>
              <th colSpan={4}>
                <div className="d-flex justify-content-between align-items-center mb-2">
                  <h3 className="m-0">LEASE CHARGES</h3>
                  <Button size="sm" color="success" onClick={this.toggleModal.bind(this)}>Change</Button>
                </div>
              </th>
            </tr>
            </thead>
            <tbody>
            {charges.map(c => <tr className={this.chargeExpired(c, lease.end_date) ? 'text-danger' : 'text-success'} key={c.id}>
              <td className="pr-1"><b>{toCurr(c.amount)}</b></td>
              <td className="pr-1">{c.charge_code}</td>
              <td>From {(!c.from_date || c.from_date === lease.start_date) ? `LEASE START ${lease.start_date}` : c.from_date}</td>
              <td>to {(!c.to_date || c.to_date === lease.end_date) ? `LEASE END ${lease.end_date}` : c.to_date}</td>
            </tr>)}
            </tbody>
          </table>
        </Col>
        <Col>
          <table>
            <thead>
            <tr>
              <th colSpan={3}>
                <h3 className="mb-2">MTM CHARGES</h3>
              </th>
            </tr>
            </thead>
            <tbody>
            {charges.map(c => !c.to_date ? <tr key={c.id}>
              <td className="pr-1"><b>{toCurr(c.amount)}</b></td>
              <td className="pr-1">{c.charge_code}</td>
              <td>From {lease.end_date}</td>
              <td>to Actual Move Out Date</td>
            </tr> : <tr key={c.id}>
              <td colSpan={4}><b>NONE!!</b></td>
            </tr>)}
            </tbody>
          </table>
        </Col>
      </Row>
      {modalOpen && <LeaseChargesModal lease={lease} charges={charges} toggle={this.toggleModal.bind(this)}/>}
    </div>;
  }
}

export default LeaseCharges;