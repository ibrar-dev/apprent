import React, {Component} from 'react';
import NewReconciliation from './newReconciliation'
import {Modal, ModalBody, Button, Row, Col, Container, Table, Label, Badge} from 'reactstrap'
import {DayPickerRangeController} from 'react-dates'
import PropertySelect from '../../../components/propertySelect'
import actions from '../actions'
import Select from '../../../components/select';
import moment from 'moment'
import {Link} from "react-router-dom";
import {connect} from 'react-redux';
import confirmation from '../../../components/confirmationModal'


class Reconciliations extends Component {

  constructor(props) {
    super(props);
    this.state = {modalOpen: false, property_id: null, postings: []};
  }

  deletePosting(id){
    confirmation("Are you sure you want to delete this reconciliation?")
    .then(() => actions.deletePosting(id))
  }

  undoPosting(id){
    confirmation("Are you sure you want to undo reconciliation?")
     actions.undoPosting(id)
  }

  setBankId = (value) => {
    actions.setBankId(value)
    actions.fetchPostings(value)
  }

  toggleModal(currentlyEditing) {
    this.setState({modalOpen: !this.state.modalOpen, currentlyEditing: currentlyEditing})
  }

  render() {
    const {modalOpen, currentlyEditing} = this.state;
    const {postings, bankAccounts, bankId} = this.props;
    return <Container>
      <Row className='justify-content-end m-2'>
        <Col md={2}>
          <Button color='success' onClick={this.toggleModal.bind(this)}>New Reconciliation</Button>
        </Col>
      </Row>
      <Row className='d-flex justify-content-start m-2 p-2 mt-5' style={{borderRadius: '10px'}}>
        <Col md={3}>
          <Label>Bank Account</Label>
          <Select
              options={bankAccounts.map(b => {
                return {label: `${b.bank_name} - ${b.name}`, value: b.id}
              })}
              name='bankId'
              onChange={({target: {name, value}}) => this.setBankId(value)}
              value={bankId}/>
        </Col>
      </Row>
      <Row className='m-2'>
        <Col md={12}>
          <table style={{width: '100%', borderCollapse: 'separate', borderSpacing: '0 1em'}} className='p-2'>
            <thead>
            <tr>
              <th>Date</th>
              <th>Created By</th>
              <th>Is Posted</th>
            </tr>
            </thead>
            <tbody>
            {postings.map((p) => {
              const {start_date, end_date, id, admin, is_posted} = p;
              return <tr className='shadow-sm' key={id} style={{height: '60px', backgroundColor: 'whitesmoke'}}>
                  <td className='p-3 align-items-center'><div style={{backgroundColor: 'white', minWidth: '210px'}} className='p-2 text-center border'>{`${moment(start_date).format('LL')}`}  -  {`${moment(end_date).format('LL')}`}</div></td>
                  <td className='p-3'>{admin}</td>
                  <td className='p-3'>{is_posted ? <i className="fas fa-check text-success"></i> :
                      <i className="fas fa-times text-danger"></i>}</td>
                  <td className='p-3'>
                    <Row className='d-flex justify-content-start'>
                      {!is_posted &&
                      <Col className='col-auto'>
                        <Link style={{width: 80}} className={`btn btn-success`} to={
                          {
                            pathname: `/reconcile/${id}`,
                          }
                        }>Resume</Link>
                    </Col>}
                    {is_posted && <Col className='col-auto'><Button color='dark' outline onClick={() => actions.postingPDF(p)}><i className="fas fa-download"></i> Report</Button></Col>}
                      {!is_posted && <Col className='col-auto'>
                        <Button color='link' onClick={this.toggleModal.bind(this, id)}>Edit</Button>
                      </Col>}
                      {!is_posted && <Col className='col-auto'>
                        <Button color='link' style={{color: 'red'}} onClick={() => this.deletePosting(id)}>Delete</Button>
                      </Col>}
                      {is_posted && <Col className='col-auto'>
                        <Button color='link' style={{color: 'red'}} onClick={() => this.undoPosting(id)}>Undo</Button>
                      </Col>}
                    </Row>
                  </td>
                </tr>
            })}
            </tbody>
          </table>
        </Col>
      </Row>
      <Modal isOpen={modalOpen} toggle={this.toggleModal.bind(this)}>
        <ModalBody>
              <NewReconciliation postings={postings} setBankId={this.setBankId.bind(this)} bank_account_id={bankId} toggleModal={this.toggleModal.bind(this)}
                                 bankAccounts={bankAccounts} {...postings.find(p => p.id == currentlyEditing)}/>
        </ModalBody>
      </Modal>
    </Container>
  }

}

export default connect(({bankAccounts, postings, bankId}) => {
  return {bankAccounts, postings, bankId}
})(Reconciliations);
