import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';
import moment from 'moment';
import Month from './month';
import Day from './day';

class Showing extends React.Component {
  state = {};

  selectDate(date) {
    this.setState({...this.state, selectedDate: date});
  }

  render() {
    const {selectedDate} = this.state;
    const formatted = moment(selectedDate).format('YYYY-MM-DD');
    const {toggle, showings, openings, prospect} = this.props;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        Schedule showing for {prospect.name}
      </ModalHeader>
      <ModalBody>
        {selectedDate && <Day date={selectedDate}
                              prospect={prospect}
                              showings={showings.filter(s => s.date === formatted)}
                              openings={openings.filter(o => o.wday === selectedDate.getDay())}
                              back={this.selectDate.bind(this)}/>}
        {!selectedDate && <Month showings={showings}
                                 selectDate={this.selectDate.bind(this)}
                                 date={selectedDate} />}
      </ModalBody>
    </Modal>
  }
}

export default connect(({property, showings, openings}) => {
  return {
    openings: openings.filter(o => o.property_id === property.id),
    showings: showings.filter(s => s.property_id === property.id)
  };
})(Showing);