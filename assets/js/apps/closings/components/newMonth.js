import React from 'react';
import moment from 'moment';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Row, Col} from 'reactstrap';
import DatePicker from '../../../components/datePicker';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';
import MonthSelect from '../../../components/datePicker/monthPicker';
import Select from "../../../components/select";

const typeOptions = [
  {value: 'payables', label: 'Payables'},
  {value: 'journal_entries', label: 'Journal Entries'}
];

class NewMonth extends React.Component {
  state = {closed_on: moment(), month: moment().date(1), type: 'payables'};

  save() {
    const {month, closed_on, type} = this.state;
    const {toggle, property} = this.props;
    confirmation(`Close all account books for ${month.format('MMMM YYYY')}?`).then(() => {
      month.date(1);
      actions.createClosing({
        property_id: property.id,
        month: month.format('YYYY-MM-DD'),
        closed_on,
        type
      }).then(toggle);
    });
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  render() {
    const {closed_on, month, type} = this.state;
    const {toggle, property} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Close Accounting Month for {property.name}
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <Select value={type} name="type" options={typeOptions} onChange={this.change.bind(this)}/>
          </Col>
          <Col>
            <MonthSelect month={month} name="month" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mt-4">
          <Col>
            Closed from date
            <DatePicker value={closed_on} name="closed_on" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Close Month
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewMonth;