import React from 'react';
import {Row, Col} from 'reactstrap';
import {connect} from 'react-redux';
import moment from 'moment';
import Month from './showing/month';
import Day from './showing/day';

class Showings extends React.Component {
  state = {};

  selectDate(date) {
    this.setState({...this.state, selectedDate: date});
  }

  render() {
    const {selectedDate} = this.state;
    const formatted = moment(selectedDate).format('YYYY-MM-DD');
    const {showings, openings, closures} = this.props;
    return <Row>
      <Col sm={{size: 8, offset: 2}}>
        {selectedDate && <Day date={selectedDate}
                              showings={showings.filter(s => s.date === formatted)}
                              closures={closures.filter(c => c.date === formatted)}
                              openings={openings.filter(o => o.wday === selectedDate.getDay())}
                              back={this.selectDate.bind(this)}/>}
        {!selectedDate && <Month showings={showings}
                                 selectDate={this.selectDate.bind(this)}
                                 date={selectedDate}/>}
      </Col>
    </Row>
  }
}

export default connect(({showings, openings, closures}) => {
  return {openings, showings, closures};
})(Showings);