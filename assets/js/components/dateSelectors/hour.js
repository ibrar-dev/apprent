import React from 'react';

const rows = [
  [
    0, 1, 2, 3, 4, 5
  ],
  [
    6, 7, 8, 9, 10, 11
  ],
  [
    12, 13, 14, 15, 16, 17
  ],
  [
    18, 19, 20, 21, 22, 23
  ],
];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {hours, value} = this.props;
    return <div className="d-flex cal-row">
      {hours.map(h => <div key={h}>
        <button className={`btn ${value && value.includes(h) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, h)}>
          {h}
        </button>
      </div>)}
    </div>
  }
}

class Hour extends React.Component {
  onclick(num) {
    this.props.onSelect(num);
  }

  render() {
    return <div>
      <h5>Select Hours:</h5>
      <div className="mx-4">
        <div className="schedule-calendar hours">
          {rows.map((r, i) => <CalRow key={i}
                                      value={this.props.value}
                                      onClick={this.onclick.bind(this)}
                                      hours={rows[i]}/>)}
        </div>
        <button className="mt-2 btn btn-block btn-outline-success" onClick={this.props.onFinish}>Done</button>
      </div>
    </div>
  }
}

export default Hour