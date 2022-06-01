import React from 'react';
import {Card, CardBody, Button, Table} from 'reactstrap';
import Pet from './pet';
import NewPet from './newPet';

class Pets extends React.Component {
  state = {};

  toggleNewPet() {
    this.setState({newPet: !this.state.newPet});
  }

  render() {
    const {pets} = this.props.tenant;
    const {newPet} = this.state;
    return <Card className="border-top-0">
      <CardBody className="p-0">
        <Table className="m-0">
          <thead>
          <tr>
            <th className="border-top-0">Type</th>
            <th className="border-top-0">Breed</th>
            <th className="border-top-0">Name</th>
            <th className="border-top-0">Weight</th>
            <th className="border-top-0 min-width"/>
            <th className="border-top-0 min-width"/>
          </tr>
          </thead>
          <tbody>
            {pets.map(p => <Pet pet={p} key={p.id}/>)}
          </tbody>
        </Table>
        <div className="p-3">
          <Button id="new-pet" style={{marginLeft: -4}} color="success" onClick={this.toggleNewPet.bind(this)}>
            <i className="fas fa-plus"/> Add Pet
          </Button>
        </div>
      </CardBody>
      <NewPet open={newPet} tenant={this.props.tenant} toggle={this.toggleNewPet.bind(this)}/>
    </Card>;
  }
}

export default Pets;