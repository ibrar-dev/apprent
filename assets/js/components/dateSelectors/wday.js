import React from 'react';

const weeks = ['1st', '2nd', '3rd', '4th'];
const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {weekdays, value} = this.props;
    return <div className="d-flex cal-row">
      {weekdays.map((w, i) => <div key={i}>
        <button className={`btn d-flex justify-content-center ${value && value.includes(i + 1) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, i + 1)}>
          {w}
        </button>
      </div>)}
    </div>
  }
}

class WDay extends React.Component {
  onclick(num) {
    this.props.onSelect(num);
  }

  render() {
    const {onFinish, value} = this.props;
    return <div>
      <h5>Select Weekday:</h5>
      <div className="mx-4">
        <div className="schedule-calendar week">
          <CalRow value={value} onClick={this.onclick.bind(this)} weekdays={weekdays}/>
        </div>
        {onFinish && <button className="mt-2 btn btn-block btn-outline-success" onClick={onFinish}>
          Done
        </button>}
      </div>
    </div>
  }
}

export default WDay;