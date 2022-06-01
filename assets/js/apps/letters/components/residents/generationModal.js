import React, {Component} from 'react';
import {Modal, ModalBody, Button, ModalFooter, Table} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../../actions';

class GenerationModal extends Component {
  state = {
    page: 0,
    visible: false,
    notify: false
  };

  residentsSplit() {
    const {residents, selectedResidents} = this.props;
    return residents.filter(r => selectedResidents.includes(r.id));
  }

  generateLetters() {
    const {selectedResidents, letter} = this.props;
    const {visible, notify} = this.state;
    actions.generateLetters({
      tenant_ids: selectedResidents,
      template_id: letter,
      visible: visible,
      notify: notify
    }).then(r => {
      this.setState({...this.state, started: true})
    })
  }

  toggle(type) {
    if (type === 'notify' && !this.state.notify) return this.setState({...this.state, notify: true, visible: true});
    if (type === 'visible' && this.state.notify) return this.setState({
      ...this.state,
      notify: false,
      visible: !this.state.visible
    });
    this.setState({...this.state, [type]: !this.state[type]})
  }

  calculateSeconds() {
    const {selectedResidents} = this.props;
    let seconds = selectedResidents.length * 2;
    let minutes = Math.round((selectedResidents.length * 2) / 60);
    let secondsMessage = <span>{seconds} seconds.</span>
    let minutesMessage = <span>{minutes} minutes.</span>
    return seconds < 60 ? secondsMessage : minutesMessage;
  }

  render() {
    const {selectedResidents, toggle, letter} = this.props;
    const {visible, notify, started} = this.state;
    return <Modal isOpen={true} size="lg" toggle={toggle}>
      <div className="d-flex modal-header justify-content-between">
        <div className="d-flex flex-column">
          <span>Approve {letter.name} for {selectedResidents.length} Residents</span>
          <small>Resident will {notify ? '' : 'NOT'} be notified after letter gets generated.</small>
          <small>This document will {visible ? '' : 'NOT'} be visible for residents to view.</small>
        </div>
        {!started && <div>
          <i onClick={this.toggle.bind(this, 'notify')}
             className={`mr-3 cursor-pointer fas fa-flag text-${notify ? 'success' : 'danger'}`}/>
          <i onClick={this.toggle.bind(this, 'visible')}
             className={`cursor-pointer fas fa-eye text-${visible ? 'success' : 'danger'}`}/>
        </div>}
      </div>
      <ModalBody className="p-0">
        {started && <div className="p-1">
          <p>The letter generation has been started. Please note that no further action is required on your part.</p>
          <p>When the letters are fully generated you will receive an email with all the letters in one PDF for easy printing.</p>
          <p>Also note that the letters will automatically be uploaded to the residents account.</p>
          <p>Lastly, it takes on average 1-2 seconds to generate and save each letter, this means you can expect to see the email in approximately {this.calculateSeconds()}</p>
        </div>}
        {!started && <Table className="m-0">
          <tbody>
          <tr>
            <th></th>
            <th>Unit</th>
            <th>Name</th>
            <th>ID</th>
          </tr>
          {this.residentsSplit().map((r, i) => {
            return <tr key={r.id}>
              <td>{i+1}</td>
              <td>{r.unit}</td>
              <td>{r.first_name} {r.last_name}</td>
              <td>{r.id}</td>
            </tr>
          })}
          </tbody>
        </Table>}
      </ModalBody>
      <ModalFooter>
        {!started &&
        <Button onClick={this.generateLetters.bind(this)} disabled={selectedResidents.length <= 0} outline
                color="success">Generate and Print</Button>}
        {started &&
        <h5>Letters Generated and saved to the residents account. There is no need to upload the documents.</h5>}
      </ModalFooter>
    </Modal>
  }
}

export default connect(({selectedResidents, residents}) => {
  return {selectedResidents, residents}
})(GenerationModal)