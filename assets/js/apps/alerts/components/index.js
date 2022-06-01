import React, {Component, Fragment} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Card, CardBody, CardHeader, Table, Button, Collapse, Input} from 'reactstrap';
import moment from 'moment';
import actions from '../actions';
import {titleize} from "../../../utils";
import icons from '../../../components/flatIcons';
import canEdit from '../../../components/canEdit';
import Pagination from '../../../components/pagination';
import Alert from './alert';
import confirmation from "../../../components/confirmationModal";

const headers = [
  {label: 'Read', min: true, sort: 'read'},
  {label: "Priority", sort: 'flag'},
  {label: "Sender", sort: 'sender'},
  {label: "Note", sort: 'note'},
  {label: <i className="fas fa-paperclip" />, min: true},
  {label: "Date", sort: 'inserted_at'},
];

class Alerts extends Component {
  state = {
    sort: {
      type: null,
      order: 'asc'
    },
    filterVal: "",
    read: false
  }

  deleteAll() {
    const {alerts} = this.props
      this.timer = setTimeout(() => {
        confirmation('Are you sure you want to delete all alerts?').then(() => {
          alerts.forEach(alert => actions.deleteAlert(alert.id))
          })
        }, 1000);
  }
    invalidateTimer() {
      clearTimeout(this.timer);
    }

  toggleRead(event) {
    const {alerts} = this.props
    this.setState({ read: !this.state.read})
    alerts.forEach(alert => actions.readAlert(alert.id))
  }

  toggleUnread(event) {
    const {alerts} = this.props
    alerts.forEach(alert => actions.unreadAlert(alert.id))
  }

  menuDisplay(){
    if(canEdit(["Super Admin", "Regional"])){
      return[
        {title: 'Read All', onClick: this.toggleRead.bind(this)},
        {title: 'Unread All', onClick: this.toggleUnread.bind(this)},
        {title: "Delete All", onClick: this.deleteAll.bind(this)}]
    }
    else{
      return[
        {title: 'Read All', onClick: this.toggleRead.bind(this)},
        {title: 'Unread All', onClick: this.toggleUnread.bind(this)}]
    }
  }

  hasAlerts() {
    const {alerts, readAlerts} = this.props;
    return alerts.length >= 1 || readAlerts.length >= 1
  }

  classToDisplay(flag) {
    switch (flag) {
      case 5:
        return 'table-danger';
      case 4:
        return 'table-warning';
      case 3:
        return 'table-primary';
      default:
        return '';
    }
  }

  setSort(type) {
    const {sort} = this.state;
    sort.type = type;
    sort.order === 'asc' ? sort.order = 'desc' : sort.order = 'asc';
    this.setState({...this.state, sort})
  }

  sortAlerts(alerts) {
    const {sort: {type, order}} = this.state;
    if (type) {
      if (order === 'asc') {
        return alerts.sort(function(a, b) {
          return a[type] - b[type]
        })
      } else {
        return alerts.sort(function(a, b) {
          return b[type] - a[type]
        })
      }
    } else {
      return alerts;
    }
  }

  setActiveAlert(alert) {
    !alert.read ? actions.readAlert(alert.id) : null;
    this.setState({...this.state, activeAlertID: alert.id})
  }

  updateRead(alert) {
    actions.updateAlert(alert);
  }

  toggleHistory() {
    this.setState({...this.state, history: !this.state.history})
  }

  deleteAlert(alertId) {
    actions.deleteAlert(alertId)
  }

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  render() {
    const {alerts} = this.props;
    const {activeAlertID, history, filterVal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    const activeAlert = alerts.filter(a => a.id === activeAlertID)[0];
    return <Card>
      <CardBody>
        {this.hasAlerts() && <Row>
          <Col sm={8}>
            <Pagination component={Alert}
                        collection={alerts.filter(a => filter.test(a.sender) || filter.test(a.note))}
                        title={<div />}
                        headers={headers}
                        filters={this._filters()}
                        additionalProps={{activeAlertID: activeAlertID, setActiveAlert: this.setActiveAlert.bind(this), updateRead: this.updateRead.bind(this)}}
                        field="alert"
                        className="h-100 border-left-0 rounded-0"
                        menu={this.menuDisplay.bind(this)()}
            />
          </Col>
          <Col md={4}>
            {activeAlert && <Card>
              <CardHeader className='d-flex justify-content-between'><span>Active Alert</span><i onClick={this.updateRead.bind(this, activeAlert)} style={{cursor: 'pointer'}} className={`fas fa-${activeAlert.read ? 'envelope-open' : 'envelope'}`} /></CardHeader>
              <CardBody>
                <p>From: <b>{activeAlert.sender}</b></p>
                <p>{activeAlert.note}</p>
                {canEdit(["Super Admin", "Regional"]) && <div>
                  <Button onClick={this.toggleHistory.bind(this)} outline color="success">{history ? 'Hide' : 'View'} History</Button>
                  <Collapse isOpen={history}>
                    <Table>
                      <thead>
                        <tr>
                          <th>Change</th>
                          <th>Time</th>
                        </tr>
                      </thead>
                      <tbody>
                      {activeAlert.history.map((h, i) => {
                        return <tr key={i}>
                          <td>{titleize(h.change)}</td>
                          <td>{moment.utc(h.time).format("M/D/YY h:mm")}</td>
                        </tr>
                      })}
                      </tbody>
                    </Table>
                  </Collapse>
                </div>}
              </CardBody>
            </Card>}
          </Col>
        </Row>}
        {!this.hasAlerts() && <Row>
          <Col/>
          <Col>
            <h4>No Alerts at this time</h4>
          </Col>
          <Col/>
        </Row>}
      </CardBody>
    </Card>
  }
}


export default connect(({alerts, readAlerts}) => {
  return {alerts, readAlerts};
})(Alerts);