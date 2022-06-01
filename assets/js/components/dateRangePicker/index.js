import React from 'react';
import DatePicker from "../datePicker";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";

class ACDateRangePicker extends React.Component {
  state = {};

  changeDate(name, val) {
    const newState = {...this.props, [name]: val};
    const {startDate, endDate} = newState;
    this.props.onDatesChange({startDate, endDate});
  }

  render() {
    const {startDate, endDate, clearField, isOutsideRange} = this.props;
    return <div className="d-flex align-items-center">
      <div className="d-flex position-relative">
        <DatePicker value={startDate} onChange={this.changeDate.bind(this, 'startDate')}
                    isOutsideRange={isOutsideRange}/>
        {clearField && startDate &&
        <i className="fas fa-times position-absolute" style={{alignSelf: 'center', right: 11}}
           onClick={() => this.changeDate('startDate', null)}/>}
      </div>
      <svg viewBox="0 0 36 36" style={{width: 36, height: 18}}>
        <polyline points="25.2,9 33.6,18 25.2,27" style={{fill: 'none', stroke: '#000', strokeWidth: 1.5}}/>
        <line x1="1.2" y1="18" x2="33.5" y2="18" style={{stroke: '#000', strokeWidth: 1.5}}/>
      </svg>
      <div className="d-flex position-relative">
        <DatePicker value={endDate} onChange={this.changeDate.bind(this, 'endDate')}
                    isOutsideRange={(day) => (typeof(isOutsideRange) == 'function' ? isOutsideRange(day) : false) || isInclusivelyBeforeDay(day, startDate)}/>
        {clearField && endDate &&
        <i className="fas fa-times position-absolute" style={{alignSelf: 'center', right: 11}}
           onClick={() => this.changeDate('endDate', null)}/>}
      </div>
    </div>
  }
}

export default ACDateRangePicker;
