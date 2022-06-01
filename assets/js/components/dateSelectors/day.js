import React from 'react';

const rows = [
  [
    1, 2, 3, 4, 5, 6, 7
  ],
  [
    8, 9, 10, 11, 12, 13, 14
  ],
  [
    15, 16, 17, 18, 19, 20, 21
  ],
  [
    22, 23, 24, 25, 26, 27, 28
  ],
  [
    29, 30, 31
  ],
];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {days, value} = this.props;
    return <div className="d-flex cal-row">
      {days.map(d => <div key={d}>
        <button className={`btn ${value && value.includes(d) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, d)}>
          {d}
        </button>
      </div>)}
    </div>
  }
}

class Day extends React.Component {
  onclick(num) {
    this.props.onSelect(num);
  }

  render() {
    const {onFinish} = this.props;
    return <div>
      <h5>Select Days:</h5>
      <div className="mx-4">
        <div className="schedule-calendar days">
          {rows.map((r, i) => <CalRow key={i} value={this.props.value} onClick={this.onclick.bind(this)}
                                      days={rows[i]}/>)}
        </div>
        {onFinish && <button className="mt-2 btn btn-block btn-outline-success" onClick={onFinish}>
          Done
        </button>}
      </div>
    </div>
  }
}

export default Day