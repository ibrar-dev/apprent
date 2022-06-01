import React from 'react';

const year = (new Date()).getFullYear();
const rows = [
  [
    year, year + 1
  ]
];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {years, value} = this.props;
    return <div className="d-flex cal-row">
      {years.map(y => <div style={{width: '50%'}} key={y}>
        <button className={`btn ${value && value.includes(y) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, y)}>
          {y}
        </button>
      </div>)}
    </div>
  }
}

class Year extends React.Component {
  onclick(num) {
    this.props.onSelect(num);
  }

  render() {
    return <div>
      <h5>Select Years:</h5>
      <div className="mx-4">
        <div className="schedule-calendar years">
          {rows.map((r, i) => <CalRow key={i}
                                      value={this.props.value}
                                      onClick={this.onclick.bind(this)}
                                      years={rows[i]}/>)}
        </div>
        <button className="mt-2 btn btn-block btn-outline-success" onClick={this.props.onFinish}>Done</button>
      </div>
    </div>
  }
}

export default Year;