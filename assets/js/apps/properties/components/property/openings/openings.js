import React from 'react';
import {Card, CardBody, Table} from 'reactstrap';
import Day from './day';

const indexArray = ([...new Array(7)]);

class Openings extends React.Component {
  render() {
    const {openings, property} = this.props;
    const sorted = [];
    indexArray.forEach((g, i) => sorted[i] = []);
    openings.forEach(opening => sorted[opening.wday].push(opening));
    return <Card className="ml-2">
      <CardBody>
        <h3>{property.name}</h3>
        <Table bordered className="m-0">
          <thead>
          <tr className="text-center">
            <th className="bg-light" style={{width: '14.285%'}}>Sun</th>
            <th className="bg-light" style={{width: '14.285%'}}>Mon</th>
            <th className="bg-light" style={{width: '14.285%'}}>Tue</th>
            <th className="bg-light" style={{width: '14.285%'}}>Wed</th>
            <th className="bg-light" style={{width: '14.285%'}}>Thu</th>
            <th className="bg-light" style={{width: '14.285%'}}>Fri</th>
            <th className="bg-light" style={{width: '14.285%'}}>Sat</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            {indexArray.map((s, index) => <Day key={index}
                                               wday={index}
                                               openings={sorted[index]}/>)}
          </tr>
          </tbody>
        </Table>
      </CardBody>
    </Card>
  }
}

export default Openings;