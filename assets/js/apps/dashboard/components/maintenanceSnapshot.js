import React from 'react';
import {Card, CardHeader, CardBody, Badge} from 'reactstrap';

class MaintenanceSnapshot extends React.Component {
  state = {};

  _totalCompleted() {
    const properties = this.props.maintenanceSnapshot;
    let created = 0;
    let completed = 0;
    properties.map(p => {
      created += p.created;
      completed += p.completed;
    });
    return <div>
      <Badge pill color={created >= 30 ? 'danger' : 'success'}>{created}</Badge>
      <Badge pill color={completed >= 30 ? 'success' : 'warning'}>{completed}</Badge>
    </div>;
  }

  render() {
    const {maintenanceSnapshot} = this.props;
    return <Card>
      <CardHeader>
        <h6 className="m-0">Maintenance Snapshot</h6>
      </CardHeader>
      <CardBody>
        {maintenanceSnapshot.map(p => {
          return <div className='d-flex justify-content-between' key={p.id}>
            <span>{p.name}</span>
            <div>
              <Badge pill color={p.created <= 10 ? 'success' : 'danger'}>{p.created}</Badge>
              <Badge pill color={p.completed > 10 ? 'success' : 'warning'}>{p.completed}</Badge>
            </div>
          </div>
        })}
        <hr/>
        <div className="d-flex justify-content-between">
          <h6>Total</h6>
          {this._totalCompleted()}
        </div>
      </CardBody>
      {/*<CardFooter className='d-flex'>*/}
      {/*<span className='ml-auto'>450</span>*/}
      {/*</CardFooter>*/}
    </Card>
  }
};

export default MaintenanceSnapshot;