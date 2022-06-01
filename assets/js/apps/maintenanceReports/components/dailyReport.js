import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Table, Input, Collapse} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../actions';
import Select from '../../../components/select';
import moment from 'moment';

class DailyReport extends Component {
  state = {
    notes: '',
    selectedAdmins: [],
  };

  componentWillMount() {
    actions.fetchDailyReport()
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  _extractMakeReadiesCompleted() {
    const {dailyReport} = this.props;
    if (!dailyReport.make_readies_completed) return "";
    return dailyReport.make_readies_completed.length;
  }

  toggleViewMakeReadies(type) {
    this.setState({...this.state, [type]: !this.state[type]})
  }

  submit() {
    actions.submitDailyReport(this.state.notes, this.state.selectedAdmins).then(this.setState({...this.state, success: true}));
  }

  sortNotReady(list) {
    return list.sort((a, b) => moment(a.move_out).diff(moment(b.move_out)))
  }

  render() {
    const {isOpen, toggle, dailyReport} = this.props;
    const {notes, selectedAdmins, success, viewActiveTechs, viewMakeReadies} = this.state;
    return <Modal isOpen={isOpen} toggle={toggle} size='lg'>
      <ModalHeader toggle={toggle}>
        Daily Report Email
      </ModalHeader>
      {!success && <ModalBody>
        <Table borderless>
          <tbody>
          <tr>
            <th>Work Orders Created Today</th>
            <td>{dailyReport.created}</td>
          </tr>
          <tr>
            <th>Work Orders Completed Today</th>
            <td>{dailyReport.completed}</td>
          </tr>
          <tr>
            <th>Currently Open Work Orders</th>
            <td>{dailyReport.open}</td>
          </tr>
          <tr style={{cursor: 'pointer'}} onClick={this.toggleViewMakeReadies.bind(this, 'viewMakeReadies')}>
            <th>Currently Not Ready Units</th>
            <td>{dailyReport.not_ready_units && dailyReport.not_ready_units.length}</td>
          </tr>
          <tr>
            <th>Make Readies Completed</th>
            <td>{this._extractMakeReadiesCompleted()}</td>
          </tr>
          <tr style={{cursor: 'pointer'}} onClick={this.toggleViewMakeReadies.bind(this, 'viewActiveTechs')}>
            <th>Active Techs:</th>
            <td>{dailyReport.techs && dailyReport.techs.length}</td>
          </tr>
          </tbody>
        </Table>
        <Collapse isOpen={viewMakeReadies}>
          {dailyReport.not_ready_units && <Table striped>
            <thead>
              <tr>
                  <th>Unit</th>
                  <th>Property</th>
                  <th>Move Out Date</th>
              </tr>
            </thead>
            <tbody>
            {this.sortNotReady(dailyReport.not_ready_units).map(u => {
              return <tr key={u.id}>
                <th>{u.unit}</th>
                <td>{u.property}</td>
                <td>{moment.utc(u.move_out).local().format("MM/DD/YY")}</td>
              </tr>
            })}
            </tbody>
          </Table>}
        </Collapse>
        <Collapse isOpen={viewActiveTechs}>
          {dailyReport.techs && <Table striped>
            <tbody>
            {dailyReport.techs.map(t => {
              return <tr key={t.id}>
                <td>{t.name}</td>
              </tr>
            })}
            </tbody>
          </Table>}
        </Collapse>
        {/*<div className="form-group">*/}
          {/*<label>Techs</label>*/}
          {/*{dailyReport.techs && <Select options={dailyReport.techs.map(tech => {*/}
                                        {/*return {label: tech.name, value: tech.id};*/}
                                      {/*})}*/}
                                      {/*multi*/}
                                      {/*name="selectedTechs"*/}
                                      {/*onChange={this.change.bind(this)}*/}
                                      {/*value={selectedTechs} />}*/}
        {/*</div>*/}
        <div className="form-group">
          <label>Notes</label>
          <Input placeholder="Any notes about your day?"
                 type="textarea"
                 name="notes"
                 onChange={this.change.bind(this)}
                 value={notes}/>
        </div>
        <div className="form-group">
          <label>Recipients</label>
          {dailyReport.admins && <Select options={dailyReport.admins.map(admin => {
                                           return {label: admin.name, value: admin.id};
                                         })}
                                         multi
                                         name="selectedAdmins"
                                         onChange={this.change.bind(this)}
                                         value={selectedAdmins}/>}
        </div>
      </ModalBody>}
      {success && <ModalBody className='d-flex justify-content-center'>
        <h4>Report successfully sent! You can close this page.</h4>
      </ModalBody>}
      <ModalFooter>
        {!success && <Button outline color='success' size='sm' onClick={this.submit.bind(this)}>Submit Daily Report</Button>}
      </ModalFooter>
    </Modal>
  }
}

export default connect(({dailyReport}) => {
  return {dailyReport};
})(DailyReport);