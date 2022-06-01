import React from 'react';
import {connect} from 'react-redux';
import {Card, CardBody, Table, Row} from 'reactstrap';
import actions from '../../../actions';
import Day from './day';
import Closures from './closures';

const indexArray = ([...new Array(7)]);

class OpeningsApp extends React.Component {

  render() {
    const {property, openings} = this.props;

    const propertyOpenings = openings.filter(o => o.property_id === property.id);
    const sorted = [];
    indexArray.forEach((g, i) => sorted[i] = []);
    propertyOpenings.forEach(opening => sorted[opening.wday].push(opening));
    return <Card>
      <CardBody className="pt-1">
        <Row>
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
              {indexArray.map((s, index) => <Day key={index} wday={index} openings={sorted[index]}/>)}
            </tr>
            </tbody>
          </Table>
        </Row>
        <Closures />
      </CardBody>
    </Card>
  }
}

export default connect(({property, openings}) => {
  return {property, openings};
})(OpeningsApp);
