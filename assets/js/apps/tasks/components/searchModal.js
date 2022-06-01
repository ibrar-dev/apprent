import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Input, Row, Col} from 'reactstrap';
import DatePicker from '../../../components/datePicker';
import actions from '../actions';

class SearchModal extends React.Component {
  state = {description: ''};

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  search() {
    const {start_date, end_date, description} = this.state;
    const params = {start_date: start_date.format("YYYY-MM-DD"), end_date: end_date.format("YYYY-MM-DD"), description};
    actions.fetchTasks(params).then(this.props.toggle)
  }

  render() {
    const {toggle} = this.props;
    const {start_date, end_date, description} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Parameters</ModalHeader>
      <ModalBody>
        <Row className="mb-2">
          <Col sm={3}>From:</Col>
          <Col>
            <DatePicker name="start_date" value={start_date} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>To:</Col>
          <Col>
            <DatePicker name="end_date" value={end_date} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row>
          <Col sm={3}>Description:</Col>
          <Col>
            <Input name="description" value={description} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button onClick={this.search.bind(this)} color="success">Search</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default SearchModal;