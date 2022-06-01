import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';

class CountDown extends React.Component {
  componentWillMount() {
    this.timer = setInterval(actions.tickTime, 1000);
  }

  render() {
    const {timeoutTime, onComplete} = this.props;
    const seconds = timeoutTime % 60;
    const minutes = (timeoutTime - seconds) / 60;
    if (timeoutTime <= 0) {
      clearInterval(this.timer);
      onComplete();
      return <span>You are good to go!</span>;
    } else {
      return <span style={{color: "#007bff"}}>{minutes}:{`0${seconds}`.replace(/\d(\d\d)/, '$1')}</span>;
    }
  }
}

export default connect(({timeoutTime}) => {
  return {timeoutTime};
})(CountDown);