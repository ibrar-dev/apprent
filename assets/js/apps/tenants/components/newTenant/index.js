import React from 'react';
import {Card, CardHeader, CardBody, Button} from 'reactstrap';
import {withRouter} from 'react-router';
import Lease from "./lease";

class NewTenant extends React.Component {
  render() {
    const {history} = this.props;
    return <Card>
      <CardHeader className="d-flex justify-content-between align-items-center">
        Leases
        <Button onClick={() => history.push('/tenants', {})} size="sm" color="danger" className="m-0">
          <i className="fas fa-arrow-left"/> Back
        </Button>
      </CardHeader>
      <CardBody>
        <Lease toggle={() => history.push('/tenants', {})} />
      </CardBody>
    </Card>;
  }
}

export default withRouter(NewTenant);