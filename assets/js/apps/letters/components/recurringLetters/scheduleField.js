import React from 'react';
import dateSelectors from "../../../../components/dateSelectors";
import {capitalize} from '../../../../utils';

class ScheduleField extends React.Component {
  state = {};

  updateSchedule(e) {
    const {field, setSchedule, value} = this.props;
    const newVal = value ? (value.includes(e) ? value.filter(v => v !== e) : value.concat([e])) : [e];
    setSchedule(field, newVal.length ? newVal : null);
  }

  render() {
    const {field, value} = this.props;
    const label = capitalize(field);
    const Selector = dateSelectors[label + 'Selector'];
    return <div className="d-flex justify-content-center my-1">
      <div className="w-50">
        <Selector value={value} onSelect={this.updateSchedule.bind(this)}/>
      </div>
    </div>;
  }
}

export default ScheduleField;