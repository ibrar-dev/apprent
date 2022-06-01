import React from "react";
import {Input, Button} from 'reactstrap';
import {connect} from 'react-redux';
import Task from './task';
import Logs from './logs';
import Pagination from '../../../components/pagination';
import SearchModal from './searchModal';

const headers = [
  {label: 'Description', min: true, sort: 'description'},
  {label: 'Success?', min: true, sort: 'success'},
  {label: 'Start Time', sort: 'start_time'},
  {label: 'End Time', sort: 'end_time'},
  {label: 'Logs', min: true}
];

class TasksApp extends React.Component {
  state = {modalOpen: true};

  openLogs(logs) {
    this.setState({logs})
  }

  changeFilter({target: {value}}) {
    this.setState({filter: value})
  }

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen});
  }

  render() {
    const {tasks} = this.props;
    const {logs, filter, modalOpen} = this.state;
    const filterVal = new RegExp(filter, 'i');
    return <>
      <Pagination collection={tasks.filter(t => filterVal.test(t.description))}
                  filters={<div className="d-flex">
                    <Button onClick={this.toggleModal.bind(this)} color="success">Search</Button>
                    <Input className="ml-3" value={filter} onChange={this.changeFilter.bind(this)}/>
                  </div>}
                  additionalProps={{openLogs: this.openLogs.bind(this)}}
                  headers={headers}
                  title="Tasks"
                  component={Task}
                  field="task"/>
      {logs && <Logs toggle={this.openLogs.bind(this, null)} logs={logs}/>}
      {modalOpen && <SearchModal toggle={this.toggleModal.bind(this)}/>}
    </>;
  }
}

export default connect(({tasks}) => ({tasks}))(TasksApp)
