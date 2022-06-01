import React from 'react';
import {Input, Button} from "reactstrap";
import DateRangePicker from "../../../components/dateRangePicker";
import Select from "../../../components/select";
import actions from '../actions';

class Filters extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeDates({startDate, endDate}) {
    startDate && startDate.startOf('day');
    endDate && endDate.endOf('day');
    this.setState({startDate, endDate})
  }

  getActions() {
    const {startDate, endDate, admin} = this.state;
    actions.fetchActions({start_date: startDate, end_date: endDate, admin})
  }

  render() {
    const {startDate, endDate, admin} = this.state;
    return <div className="d-flex align-items-center mt-2 mb-3">
      <div className="mr-2">
        <Input value={admin || ''} name="admin" onChange={this.change.bind(this)} placeholder="Admin"/>
      </div>
      <div className="mr-2">
        <DateRangePicker startDate={startDate} endDate={endDate} onDatesChange={this.changeDates.bind(this)}/>
      </div>
      <div>
        <Button color="success" onClick={this.getActions.bind(this)}>Search</Button>
      </div>
    </div>;
  }
}

export default Filters;