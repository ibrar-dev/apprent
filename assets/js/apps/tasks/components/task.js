import React from 'react';
import moment from 'moment';
import {Popover, PopoverBody, PopoverHeader} from "reactstrap";

class Task extends React.Component {
  state = {};

  toggleError() {
    this.setState({errorOpen: !this.state.errorOpen});
  }

  render() {
    const {task, openLogs} = this.props;
    const {errorOpen} = this.state;
    const id = `task-error-${task.id}`;
    return <tr>
      <td className="nowrap align-middle">{task.description}</td>
      <td className="text-center align-middle">
        <i id={id} className={`cursor-pointer fas fa-2x fa-${task.success ? 'check text-success' : 'times text-danger'}`}/>
        <Popover target={id} isOpen={task.error && errorOpen} placement="top" toggle={this.toggleError.bind(this)}>
          <PopoverHeader>Error</PopoverHeader>
          <PopoverBody>{task.error}</PopoverBody>
        </Popover>
      </td>
      <td className="align-middle">{moment(task.start_time).format('MMM DD, YYYY h:mm:ss A')}</td>
      <td className="align-middle">{moment(task.end_time).format('MMM DD, YYYY h:mm:ss A')}</td>
      <td>
        <a onClick={() => openLogs(task.logs)} className="d-flex align-items-start">
          <i className="far fa-2x fa-list-alt"/>
          <span className="badge badge-pill badge-danger" style={{marginTop: -3, marginLeft: -10}}>
            {task.logs.length}
          </span>
        </a>
      </td>
    </tr>;
  }
}

export default Task;