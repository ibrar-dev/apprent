import React, { Component } from 'react';
import { Card, CardBody, CardHeader, Col, Input, Row, Modal, ModalHeader, ModalBody, Table } from "reactstrap";
import { FontAwesomeIcon } from "@fortawesome/fontawesome-free";
import moment from "moment";
import EditRecurring from './editRecurring';
import canEdit from '../../../../components/canEdit';
import confirmation from '../../../../components/confirmationModal';
import actions from '../../actions';
import { toCurr } from '../../../../utils';

class ShowRecurring extends Component {
  state = {}

  reduceToString(array) {
    return array.reduce((acc, i) => `${i} ` + acc, "")
  }

  getTime({hour, minute}) {
    const h = hour[0];
    const m = minute[0];
    return moment().startOf('day').add(h, 'h').add(m, 'm').format("hh:mm a")
  }

  getStatus(resident_params) {
    return Object.keys(resident_params).filter(o => resident_params[o] === true).reduce((acc, s) => `${s} ` + acc, "")
  }

  toggleEdit() {
    this.setState({...this.state, edit: !this.state.edit})
  }

  generateLettersEarly() {
    const {selectedLetter} = this.props;
    confirmation('Run schedule letters early?').then(() => {
      actions.generateLettersEarly(selectedLetter.id)
    });
  }

  previewTenantsList() {
    const {selectedLetter} = this.props;
    actions.previewTenantsList(selectedLetter.id)
    .then((r) => {
      this.setState({...this.state, preview: true, previewTenants: r.data});
    });
  }

  modalToggle() {
    this.setState({
      ...this.state, preview: false
    })
  }

  render() {
    const {selectedLetter, admins, letters} = this.props;
    const {edit} = this.state;
    const {resident_params, schedule} = selectedLetter;
    const admin = admins.filter(l => l.id === selectedLetter.admin_id)[0];
    const previewTenantList = this.state.previewTenants;
    return <Col>
      <Card>
        <CardHeader className={`alert-${selectedLetter.active ? 'success' : 'danger'}`}>{selectedLetter.name}</CardHeader>
        <CardBody>
          <Row>
            <Col>
              <Card>
                <CardHeader>Pertinent Info</CardHeader>
                <CardBody>
                  <div className="labeled-box">
                    <Input disabled value={letters.filter(l => l.id === selectedLetter.letter_template_id)[0].name} />
                    <div className="labeled-box-label">Letter Name</div>
                    <small>The name of the letter being generated</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={admin ? admin.name : selectedLetter.admin_id} />
                    <div className="labeled-box-label">Admin</div>
                    <small>The admin that the letters generated will get sent to</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={selectedLetter.visible ? 'Yes' : 'No'} />
                    <div className="labeled-box-label">Visible to Resident</div>
                    <small>Whether the letter will be visible for residents to view in their portal</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={selectedLetter.notify ? 'Yes' : 'No'} />
                    <div className="labeled-box-label">Notify Resident</div>
                    <small>Whether to notify the residents after the letter gets generated</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={selectedLetter.last_run ? moment.unix(selectedLetter.last_run).format("MM/DD/YY hh:mm a") : 'Not Run Yet'} />
                    <div className="labeled-box-label">Last Run</div>
                    <small>The last time the letters were auto-generated</small>
                  </div>
                </CardBody>
              </Card>
            </Col>
            <Col>
              <Card>
                <CardHeader>Schedule</CardHeader>
                <CardBody>
                  <div className="labeled-box">
                    <Input disabled value={schedule.day ? this.reduceToString(schedule.day) : 'Not Run Monthly'} />
                    <div className="labeled-box-label">Monthly</div>
                    <small>The day(s) of the month that the letters will be generated on</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={schedule.wday ? this.reduceToString(schedule.wday) : 'Not Run Weekly'} />
                    <div className="labeled-box-label">Weekly</div>
                    <small>The day(s) of the week that the letters will be generated on</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={schedule.wday && schedule.day ? 'Not Run Daily' : 'Running Daily at'} />
                    <div className="labeled-box-label">Daily</div>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={this.getTime(schedule)} />
                    <div className="labeled-box-label">Time</div>
                    <small>The time of the day that the letters will be generated</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={selectedLetter.next_run ? moment.unix(selectedLetter.next_run).format("MM/DD/YY hh:mm a") : 'Not Scheduled'} />
                    <div className="labeled-box-label">Next Run</div>
                    <small>When the letter will be generated next</small>
                  </div>
                </CardBody>
              </Card>
            </Col>
            <Col>
              <Card>
                <CardHeader>Search Parameters</CardHeader>
                <CardBody>
                  <div className="labeled-box">
                    <Input disabled value={resident_params.min_balance ? resident_params.min_balance : 'None Set'} />
                    <div className="labeled-box-label">Minimum Balance</div>
                    <small>0 Means the parameter is bypassed</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={resident_params.resident_name ? resident_params.resident_name : 'None Set'} />
                    <div className="labeled-box-label">Resident Name</div>
                    <small>Empty Means the parameter is bypassed</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={resident_params.lease_end_date ? resident_params.lease_end_date : 'None Set'} />
                    <div className="labeled-box-label">Lease End Date</div>
                    <small>Empty Means the parameter is bypassed</small>
                  </div>
                  <div className="labeled-box mt-2">
                    <Input disabled value={this.getStatus(resident_params)} />
                    <div className="labeled-box-label">Resident Status</div>
                    <small>Empty Means No Letters Are Being Generated</small>
                  </div>
                </CardBody>
              </Card>
            </Col>
          </Row>
          <Row xs="2">
          {canEdit(["Super Admin", "Regional"]) && 
            <Col className="d-flex flex-fill flex-justify-end">
              <i className="far fa-edit fa-2x" onClick={this.toggleEdit.bind(this)}/>
            </Col>
          }
          {canEdit(["Super Admin", "Regional"]) && 
            <Col>
              <i className="fas fa-running fa-2x fa-fw float-right" onClick={this.generateLettersEarly.bind(this)}/>
              <i className="fas fa-eye fa-2x fa-fw float-right" onClick={this.previewTenantsList.bind(this)}/>
            </Col>
          }
          </Row>
        </CardBody>
      </Card>
      {edit && <EditRecurring toggle={this.toggleEdit.bind(this)} selectedLetter={selectedLetter} />}
      {this.state.previewTenants &&
        <Modal isOpen={this.state.preview} size="lf" toggle={this.modalToggle.bind(this)}>
          <ModalHeader toggle={this.modalToggle.bind(this)}>
            Residents to be sent letters if the letter is run right now.
          </ModalHeader>
          <ModalBody>
            <Table borderless>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Current?</th>
                  <th>Balance</th>
                </tr>
              </thead>
              <tbody>
              {previewTenantList.map((t) => { 
                return (
                  <tr key={t.id}>
                    <td key={t.id + t.name}>{t.name}</td>
                    <td key={t.id + t.is_current}>{t.is_current? "Yes": "No"}</td>
                    <td key={t.id + t.balance} className="text-right">{toCurr(t.balance)}</td>
                  </tr> 
                );
              })}
              </tbody>
            </Table>
          </ModalBody>
        </Modal>
      }
    </Col>
  }
}

export default ShowRecurring;

