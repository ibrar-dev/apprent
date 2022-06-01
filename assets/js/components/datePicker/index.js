import React from 'react';
import moment from 'moment';
import {SingleDatePicker} from 'react-dates';
import 'react-dates/initialize';
import context from './context';
import CustomSelect from './customSelect';

const startYear = moment().year() - 100;
const months = moment.months();
const weekdays = moment.weekdaysMin();

export default class extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
    this.rootRef = React.createRef();
  }

  changeFocus({focused}) {
    if (!this.state.focused && focused) this.fixPosition = true;
    this.setState({focused});
  }

  componentDidUpdate() {
    if (this.fixPosition) {
      const el = this.rootRef.current.getElementsByClassName('SingleDatePicker_picker__directionLeft')[0];
      if (!el) return;
      el.style.top = (parseInt(el.style.top) - 11) + 'px';
      const fang = this.rootRef.current.getElementsByClassName('DateInput_fang')[0];
      fang.style.top = (parseInt(fang.style.top) - 12) + 'px';
    }
    this.fixPosition = false;
  }

  componentDidMount() {
    const {tabIndex} = this.props;
    if (tabIndex) {
      this.rootRef.current.getElementsByClassName('DateInput_input')[0].tabIndex = tabIndex;
    }
  }

  change(value) {
    const {name, onChange, clearable} = this.props;
    if (!clearable && !value) return;
    if (name) {
      onChange({target: {value, name}})
    } else {
      onChange(value);
    }
  }

  renderMonthElement({month, onMonthSelect, onYearSelect}) {
    return <div>
      <div className="d-flex justify-content-center" style={{marginTop: -4}}>
        <div className="mr-1" style={{minWidth: 108}}>
          <CustomSelect value={months[month.month()]} options={months} onSelect={v => onMonthSelect(month, v)}/>
        </div>
        <CustomSelect value={month.year()} yearMode={true} onSelect={v => onYearSelect(month, v)}
                      options={Array.from({length: 200}, (x, i) => startYear + i)}/>
      </div>
      <ul className="list-unstyled d-flex justify-content-between p-0 my-2">
        {weekdays.map(day => <li key={day} className="w-100">{day}</li>)}
      </ul>
    </div>
  }

  render() {
    const {value, required, disabled, clearable, invalid, isOutsideRange, className, placeholder, options, initialVisibleMonth, renderCalendarInfo, calendarInfoPosition} = this.props;
    const {onKeyPress} = this.props;
    const opts = options || {};
    context.id++;
    return <div style={{background: disabled ? '#f2f2f2' : '', borderColor: this.state.focused ? "blue" : ''}}
                onKeyPress={onKeyPress}
                ref={this.rootRef}
                className={`form-control pt-1 ${className || ''}` + (invalid ? ' is-invalid' : '')}>
      <SingleDatePicker {...opts}
                        date={value ? moment(value) : undefined}
                        onFocusChange={this.changeFocus.bind(this)}
                        focused={this.state.focused}
                        small
                        initialVisibleMonth={initialVisibleMonth}
                        required={required}
                        block
                        placeholder={placeholder}
                        isOutsideRange={isOutsideRange || (() => false)}
                        renderCalendarInfo={renderCalendarInfo}
                        calendarInfoPosition={calendarInfoPosition}
                        noBorder={true}
                        showClearDate={clearable}
                        numberOfMonths={1}
                        disabled={disabled}
                        renderMonthElement={this.renderMonthElement.bind(this)}
                        id={`unique-id-${context.id}`}
                        onDateChange={this.change.bind(this)}/>
    </div>
  }
}
