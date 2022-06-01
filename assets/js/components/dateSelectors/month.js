import React from 'react';

const rows = [
  [
    {name: 'Jan', num: 1},
    {name: 'Feb', num: 2},
    {name: 'Mar', num: 3},
    {name: 'Apr', num: 4}
  ],
  [
    {name: 'May', num: 5},
    {name: 'Jun', num: 6},
    {name: 'Jul', num: 7},
    {name: 'Aug', num: 8}
  ],
  [
    {name: 'Sep', num: 9},
    {name: 'Oct', num: 10},
    {name: 'Nov', num: 11},
    {name: 'Dec', num: 12},
  ],
];

class CalRow extends React.Component {
  onClick(num) {
    this.props.onClick(num);
  }

  render() {
    const {months, value} = this.props;
    return <div className="d-flex cal-row">
      {months.map(m => <div key={m.num}>
        <button className={`btn ${value && value.includes(m.num) ? 'selected' : ''}`}
                onClick={this.onClick.bind(this, m.num)}>
          {m.name}
        </button>
      </div>)}
    </div>
  }
}

class Month extends React.Component {
  onclick(num) {
    this.props.onSelect(num);
  }

  render() {
    const {onFinish} = this.props;
    return <div>
      <h5>Select Months:</h5>
      <div className="mx-4">
        <div className="schedule-calendar months">
          {rows.map((r, i) => <CalRow key={i}
                                      value={this.props.value}
                                      onClick={this.onclick.bind(this)}
                                      months={rows[i]}/>)}
        </div>
        {onFinish && <button className="mt-2 btn btn-block btn-outline-success" onClick={onFinish}>Done</button>}
      </div>
    </div>
  }
}

export default Month