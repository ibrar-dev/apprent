import React from 'react';
import moment from 'moment';
import {Card, CardHeader, CardBody, Row, Col, Pagination, PaginationItem, PaginationLink, Button} from 'reactstrap';
import ScheduleField from "./scheduleField";
import actions from '../actions';
import snackbar from "../../../components/snackbar";
import confirmation from '../../../components/confirmationModal';

const newJob = (worker) => {
  const schedule = {day: null, hour: null, minute: null, month: null, wday: null, week: null, year: null};
  return {function: worker, schedule, arguments: []}
};

class Job extends React.Component {
  state = {activeJob: this.props.worker.data.jobs[0] || this.newJob(), workerId: this.props.worker.id};

  static getDerivedStateFromProps(props, state) {
    if (props.worker.id !== state.workerId) {
      return {activeJob: props.worker.data.jobs[0] || newJob(props.worker.id), workerId: props.worker.id}
    }
    return state;
  }

  changeJobSchedule(params) {
    const newActiveJob = this.state.activeJob;
    newActiveJob.schedule = {...newActiveJob.schedule, ...params};
    this.setState({activeJob: newActiveJob})
  }

  newJob() {
    return newJob(this.props.worker.id)
  }

  setJob(job) {
    this.setState({activeJob: job || this.newJob()})
  }

  save() {
    const {activeJob} = this.state;
    const promise = activeJob.id ? actions.updateJob(activeJob) : actions.createJob(activeJob);
    promise.then(() => {
        snackbar({
          message: "Job saved successfully",
          args: {type: 'success'}
        });
        setTimeout(() => {
          this.setState({activeJob: this.props.worker.data.jobs[0] || this.newJob(), workerId: this.props.worker.id});
        }, 250);
      }
    );
  }

  deleteJob() {
    confirmation('Delete this job?').then(() => {
      actions.deleteJob(this.state.activeJob.id).then(() => snackbar({
        message: "Job deleted successfully",
        args: {type: 'success'}
      }))
    });
  }

  render() {
    const {worker} = this.props;
    const {activeJob} = this.state;
    const jobs = worker.data.jobs;
    return <Card className="ml-2">
      <CardHeader className="d-flex align-items-center justify-content-between">
        {worker.data.desc}
        <Pagination listClassName="m-0">
          {jobs.map((job, i) => {
            return <PaginationItem key={job.id} active={activeJob.id === job.id}>
              <PaginationLink onClick={this.setJob.bind(this, job)}>
                {i + 1}
              </PaginationLink>
            </PaginationItem>
          })}
          <PaginationItem active={!activeJob.id}>
            <PaginationLink onClick={this.setJob.bind(this, null)}>
              New
            </PaginationLink>
          </PaginationItem>
        </Pagination>
      </CardHeader>
      <CardBody>
        <Row>
          <Col sm={6}>
            {['year', 'month', 'day', 'hour', 'minute'].map(field =>
              <ScheduleField key={field} jobId={activeJob.id} onChange={this.changeJobSchedule.bind(this)}
                             field={field} value={activeJob.schedule[field]}/>)}
            <div className="mt-3 d-flex">
              <Button className="mr-2" color="success" onClick={this.save.bind(this)}>Save</Button>
              {activeJob.id && <Button color="danger" onClick={this.deleteJob.bind(this)}>Delete</Button>}
            </div>
          </Col>
          <Col>
            <div>
              Last run: {activeJob.last_run ? moment.unix(activeJob.last_run).format('MM/DD/YYYY hh:mm A') : '--'}
            </div>
            <div>Next run: {moment.unix(activeJob.next_run).format('MM/DD/YYYY hh:mm A')}</div>
          </Col>
        </Row>
      </CardBody>
    </Card>;
  }
}

export default Job;
