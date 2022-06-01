import React from "react";
import dateSelectors from "../../../components/dateSelectors";
import {capitalize} from "../../../utils";

class ScheduleField extends React.Component {
  state = {value: this.props.value, jobId: this.props.jobId};

  static getDerivedStateFromProps(props, state) {
    if (props.jobId !== state.jobId) {
      return {value: props.value, jobId: props.jobId}
    }
    return state;
  }

  toggleEdit() {
    this.setState({edit: !this.state.edit});
  }

  changeValue(v) {
    const currentValue = this.state.value || [];
    let newVal;
    if (currentValue.includes(v)) {
      newVal = currentValue.filter(val => val !== v);
    } else {
      newVal = currentValue.concat([v]);
    }
    newVal.sort();
    const {field, onChange} = this.props;
    onChange({[field]: newVal});
    this.setState({value: newVal.length > 0 ? newVal : null});
  }

  render() {
    const {field} = this.props;
    const {value, edit} = this.state;
    const Selector = dateSelectors[capitalize(field) + 'Selector'];
    const label = capitalize(field);
    return <div>
      {!edit && <a onClick={this.toggleEdit.bind(this)}>
        {value ? `${label + 's'}: ${value.join(', ')}` : `Every ${label}`}
      </a>}
      {edit && <div className="my-1">
        <Selector value={value}
                  onFinish={this.toggleEdit.bind(this)}
                  onSelect={this.changeValue.bind(this)}/>
      </div>}
    </div>
  }
}

export default ScheduleField;