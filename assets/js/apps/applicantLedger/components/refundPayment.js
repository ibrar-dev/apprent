import React from 'react';
import moment from 'moment';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Row, Col} from 'reactstrap';
import Check from './check';
import actions from '../actions';
import {numToLang} from '../../../utils';
import Select from '../../../components/select';
import Checkbox from '../../../components/fancyCheck';
import printPdf from '../../../utils/pdfPrinter';
import snackbar from '../../../components/snackbar'

class RefundPayment extends React.Component {
  constructor(props) {
    super(props);
    actions.fetchBankAccounts(props.payment.property_id);
    this.state = {printCheck: false};
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  refund() {
    const {toggle, payment} = this.props;
    const {applicant_id, bank_account_id, printCheck} = this.state;
    const date = moment().format('YYYY-MM-DD');
    actions.updatePayment({...payment, refund_date: date}).then(() => {
      if (printCheck) {
        actions.createCheck({
          amount: payment.amount,
          amount_lang: numToLang(payment.amount),
          applicant_id,
          bank_account_id,
          date
        }).then(r => {
          printPdf(r.data.check_pdf);
        }).catch(r => {
          snackbar({message: r.response.data.error, args: {type: "error"}});
        });
      } else {
        toggle();
      }
    });
  }

  toggleCheck() {
    this.setState({printCheck: !this.state.printCheck});
  }

  checkParams() {
    const {payment, bankAccounts, applicants} = this.props;
    const {applicant_id, bank_account_id} = this.state;
    const date = moment().format('YYYY-MM-DD');
    const account = bankAccounts.find(b => b.id === bank_account_id);
    return {
      bank_account: account,
      payee: applicants.find(a => a.id === applicant_id).full_name,
      amount: payment.amount,
      number: (account.max_number || 0) + 1,
      date
    }
  }

  render() {
    const {toggle, bankAccounts, applicants} = this.props;
    const {applicant_id, bank_account_id, printCheck} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        Refund Payment
      </ModalHeader>
      <ModalBody>
        <div>
          <Checkbox checked={printCheck} label="Print Check" onChange={this.toggleCheck.bind(this)}/>
        </div>
        {printCheck && <Row className="mt-2">
          <Col>
            <Select options={applicants.map(a => ({value: a.id, label: a.full_name}))} name="applicant_id"
                    value={applicant_id} onChange={this.change.bind(this)}/>
          </Col>
          <Col>
            <Select options={bankAccounts.map(a => ({value: a.id, label: a.name}))} name="bank_account_id"
                    value={bank_account_id} onChange={this.change.bind(this)}/>
          </Col>
        </Row>}
        {printCheck && bank_account_id && applicant_id && <Check check={this.checkParams()}/>}
      </ModalBody>
      <ModalFooter className="justify-content-center">
        <Button disabled={printCheck && (!applicant_id || !bank_account_id)} className="w-50" color="success"
                onClick={this.refund.bind(this)}>
          Issue Refund
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({bankAccounts, applicants}) => ({bankAccounts, applicants}))(RefundPayment);
