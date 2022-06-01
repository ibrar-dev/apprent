import React from 'react';
import {connect} from 'react-redux';
import Calendar from './calendar';
import ManagerDashboard from './managerDashboard';
import {Container} from 'reactstrap';

class Dashboard extends React.Component {

  render() {
    const {events, maintenanceSnapshot} = this.props;
    return <React.Fragment>
      <Container style={{maxWidth:"1300px"}}>
      <ManagerDashboard />
      <Calendar events={events} maintenanceSnapshot={maintenanceSnapshot}/>
      </Container>
    </React.Fragment>
  }
}

export default connect(({events, maintenanceSnapshot}) => {
  return {events, maintenanceSnapshot};
})(Dashboard);