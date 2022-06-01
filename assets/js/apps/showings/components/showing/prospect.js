import React from 'react';
import moment from 'moment';
import {Modal, ModalHeader, ModalBody, Row, Col, Input, Button} from 'reactstrap';
import {RingLoader} from 'react-spinners';
import actions from '../../actions';

const row = (label, field, prospect, change, date = false, required) => {
  return <Row className="my-2">
    <Col sm={4} className="d-flex align-items-center">
      {label}
    </Col>
    <Col sm={8}>
      <Input value={prospect[field] || ''} name={field} onChange={change} className={`is-${required}`}/>
    </Col>
  </Row>;
};

const readable = (num) => {
  let hour = Math.floor(num / 60.0);
  let period = 'AM';
  const minute = ((num % 60.0) + '0').replace('300', '30');
  if (hour > 12) {
    period = 'PM';
    hour = hour - 12;
  }
  return `${hour}:${minute}${period}`;
};

class Prospect extends React.Component {
  state = {};

  create() {
    const {start, duration, date} = this.props;
    this.setState({...this.state, pending: true});
    actions.createShowing({
      ...this.state,
      start_time: start,
      end_time: start + duration,
      date
    }).then(r => {
      this.setState({...this.state, success: true, pending: false});
      setTimeout(() => location.reload(), 10000);
    }).catch(r => {});
  }

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  render() {
    const {toggle, date, start, duration} = this.props;
    const prospect = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        Tell us a bit about yourself
      </ModalHeader>
      <ModalBody>
        {!prospect.success && <React.Fragment>
          <Row>
            <Col sm={{size: 10, offset: 1}} className="text-center">
              You have requested a {duration} minute showing on {moment(date).format('MM/DD/YYYY')} at {readable(start)}
            </Col>
          </Row>
          {prospect.pending ? <h2 className="text-center">Please wait a moment while we confirm your appointment.</h2>
            :
          <Row>
            <Col sm={{size: 10, offset: 1}}>
              {row("Name", "name", prospect, change)}
              {row("Email", "email", prospect, change)}
            </Col>
          </Row>}
          <Row className="mt-3">
            <Col sm={{size: 10, offset: 1}}>
              <Button color="info"
                      disabled={!prospect.name || !prospect.email}
                      className="text-white d-flex flex-row justify-content-center" block={true} onClick={this.create.bind(this)}>
                {prospect.pending ? <RingLoader loading={true} size={60} color="#312f43" /> : 'Schedule Showing'}
              </Button>
            </Col>
          </Row>
        </React.Fragment>}
        {prospect.success && <h2 className="text-center">
          Thank you, your showing has been scheduled successfully!
        </h2>}
      </ModalBody>
    </Modal>;
  }
}

export default Prospect;