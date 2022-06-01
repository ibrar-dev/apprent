import React from 'react';

const rows = [
  [
    0, 5, 10, 15
  ],
  [
    20, 25, 30, 35
  ],
  [
    40, 45, 50, 55
  ]
];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {minutes, value} = this.props;
    return <div className="d-flex cal-row">
      {minutes.map(m => <div key={m}>
        <button className={`btn ${value && value.includes(m) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, m)}>
          {m}
        </button>
      </div>)}
    </div>
  }
}

class Minute extends React.Component {
  onClick(num) {
    this.props.onSelect(num);
  }

  render() {
    const {value} = this.props;
    return <div>
      <h5>Select Minutes:</h5>
      <div className="mx-4">
        <div className="schedule-calendar minutes">
          {rows.map((r, i) => <CalRow key={i}
                                      value={value}
                                      onClick={this.onClick.bind(this)}
                                      minutes={rows[i]}/>)}
          {value && value.map(v => v % 5 > 0 ? <div key={v} className="d-flex">
            <button className={`btn rounded-0 btn-block btn-dark`}
                    onClick={this.onClick.bind(this, v)}>
              {v}
            </button>
          </div> : null)}
        </div>
        <button className="mt-2 btn btn-block btn-outline-success" onClick={this.props.onFinish}>Done</button>
      </div>
    </div>
  }
}

export default Minute