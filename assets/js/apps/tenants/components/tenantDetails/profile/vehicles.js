import React from 'react';
import {Card, CardBody, Button, Table} from 'reactstrap';
import Vehicle from './vehicle';
import NewVehicle from './newVehicle';

class Vehicles extends React.Component {
  state = {};

  toggleNewVehicle() {
    this.setState({newVehicle: !this.state.newVehicle});
  }

  render() {
    const {vehicles} = this.props.tenant;
    const {newVehicle} = this.state;
    return <Card className="border-top-0">
      <CardBody className="p-0">
        <Table className="m-0">
          <thead>
          <tr>
            <th className="border-top-0">Make/Model</th>
            <th className="border-top-0">Color</th>
            <th className="border-top-0">LP Number</th>
            <th className="border-top-0" style={{minWidth: 275}}>State</th>
            <th className="border-top-0 min-width"/>
            <th className="border-top-0 min-width"/>
          </tr>
          </thead>
          <tbody>
          {vehicles.map(v => <Vehicle vehicle={v} key={v.id}/>)}
          </tbody>
        </Table>
        <div className="p-3">
          <Button id="new-vehicle" style={{marginLeft: -4}} color="success" onClick={this.toggleNewVehicle.bind(this)}>
            <i className="fas fa-plus"/> Add Vehicle
          </Button>
        </div>
      </CardBody>
      <NewVehicle open={newVehicle} tenant={this.props.tenant} toggle={this.toggleNewVehicle.bind(this)}/>
    </Card>;
  }
}

export default Vehicles;