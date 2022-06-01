import React from 'react';
import {Card} from 'reactstrap';
import Header from './header';
import Body from './body';

class Occupancy extends React.Component {
  render() {
    const {tenant} = this.props;
    const lastLease = tenant.leases.sort((a, b) => a.start_date > b.start_date ? -1 : 1)[0];
    return <Card className={`ml-3${tenant.eviction_file_date ? ' alert-danger' : ''}`}>
      <Header tenant={tenant} lease={lastLease}/>
      <Body tenant={tenant} lease={lastLease}/>
    </Card>
  }
}

export default Occupancy