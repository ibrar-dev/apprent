import React from 'react';
import {Dropdown, DropdownToggle, DropdownMenu, DropdownItem} from 'reactstrap';

const monthOptions = [
  {label: 'January', value: 0},
  {label: 'February', value: 1},
  {label: 'March', value: 2},
  {label: 'April', value: 3},
  {label: 'May', value: 4},
  {label: 'June', value: 5},
  {label: 'July', value: 6},
  {label: 'August', value: 7},
  {label: 'September', value: 8},
  {label: 'October', value: 9},
  {label: 'November', value: 10},
  {label: 'December', value: 11},
];

const currentYear = (new Date).getFullYear();

class MonthPicker extends React.Component {
  constructor(props) {
    super(props);
    if (props.month) props.month.date(1);
    this.state = {};
    this.yearRef = React.createRef();
    this.monthRef = React.createRef();
  }

  changeDate(name, value) {
    const {month, onChange} = this.props;
    const newMonth = month.clone();
    newMonth[name](value);
    onChange({target: {name: this.props.name, value: newMonth}});
  }

  yearOptions() {
    const {yearStart, yearEnd} = this.props;
    const start = (yearStart || currentYear - 100);
    const end = (yearEnd || currentYear + 100);
    return Array.from({length: end - start}, (_, i) => start + i);
  }

  toggleYear() {
    this.setState({yearOpen: !this.state.yearOpen});
    setTimeout(() => {
      const index = this.yearOptions().findIndex(year => year === this.props.month.year());
      this.yearRef.current.scroll(0, index * 42);
    }, 10);
  }

  toggleMonth() {
    this.setState({monthOpen: !this.state.monthOpen});
    setTimeout(() => {
      const index = monthOptions.findIndex(month => month.value === this.props.month.month());
      this.monthRef.current.scroll(0, index * 42);
    }, 10);
  }

  render() {
    const {month, className} = this.props;
    const {monthOpen, yearOpen} = this.state;
    return <div className={`d-inline-flex month-picker ${className}`}>
      <Dropdown isOpen={monthOpen} toggle={this.toggleMonth.bind(this)}>
        <DropdownToggle color="outline-white"
                        className="rounded-0 month-button d-flex justify-content-between align-items-center " caret>
          {monthOptions[month.month()].label}
        </DropdownToggle>
        <DropdownMenu>
          <div ref={this.monthRef}>
            {monthOptions.map(opt => <DropdownItem key={opt.value}
                                                   className={month.month() === opt.value ? 'bg-info text-white' : ''}
                                                   onClick={this.changeDate.bind(this, 'month', opt.value)}>
              {opt.label}
            </DropdownItem>)}
          </div>
        </DropdownMenu>
      </Dropdown>
      <Dropdown isOpen={yearOpen} toggle={this.toggleYear.bind(this)}>
        <DropdownToggle color="outline-white" className="rounded-0 d-flex justify-content-between align-items-center"
                        caret>
          {month.year()}
        </DropdownToggle>
        <DropdownMenu>
          <div ref={this.yearRef}>
            {this.yearOptions().map(opt => <DropdownItem key={opt}
                                                         className={month.year() === opt ? 'bg-info text-white' : ''}
                                                         onClick={this.changeDate.bind(this, 'year', opt)}>
              {opt}
            </DropdownItem>)}
          </div>
        </DropdownMenu>
      </Dropdown>
    </div>;
  }
}

export default MonthPicker;