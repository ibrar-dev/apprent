import React, {Component} from 'react';
import {Card, CardBody, CardFooter} from 'reactstrap';
import Charges from './charges';
import Header from './header';
import Parameters from './parameters';

class BatchesApp extends Component {

  render() {
    return <Card>
      <Header/>
      <CardBody className="p-0">
        <Charges/>
      </CardBody>
      <CardFooter>
        <Parameters/>
      </CardFooter>
    </Card>;
  }
}

export default BatchesApp;