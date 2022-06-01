import React from 'react';
import {Row, Col, Card, CardHeader, CardBody,Popover,PopoverHeader,PopoverBody,Button} from 'reactstrap';
import {Link} from 'react-router-dom';
import moment from 'moment';
import Notes from './notes';

class CanceledOrder extends React.Component {
  state = {}
  showUnit(){
    this.setState({...this.state, unit: !this.state.unit});
  }

  render() {
    const {order} = this.props;
    const {unit} = this.state;
    return (
      <Card>
        <CardHeader className="d-flex justify-content-between">
          <Link to="/orders" className="btn btn-danger btn-sm m-0">
            <i className="fas fa-arrow-left"/> Back
          </Link>
          <h3 className="mb-0">{order.property.name} {order.unit}: {order.tenant}
            {order.unit && <Button id="unit" color="link" size= "sm" onClick={this.showUnit.bind(this)}>Unit Info</Button>}
          </h3>
          {order.unit && <Popover placement="right" isOpen={unit} target="unit" toggle={this.showUnit.bind(this)}>
            <PopoverHeader>Unit Details</PopoverHeader>
            <PopoverBody>
              Floor Plan: {order.unit_floor_plan ? order.unit_floor_plan : "N/A"} <br/>
              Area: {order.unit_area ? order.unit_area : "N/A"} <br/>
              Status: {order.unit_status ? order.unit_status : "N/A"} <br/>
            </PopoverBody>
          </Popover>}
          <div />
        </CardHeader>
        <CardBody className={`border p-2 ${order.priority === 3 ? 'alert-danger' : ''}`}>
          <Row>
            <Col sm={6}>
              <h4>{order.category}</h4>
              <h5>
                Canceled by {order.cancellation.admin} on {moment(order.cancellation.time).format('MM/DD/YYYY h:mmA')}
              </h5>
              <h5>Reason <b>{order.cancellation.reason || 'No Reason Given'}</b></h5>
              <div>{order.has_pet && 'Has Pet'}</div>
              <div>{order.entry_allowed && 'Entry Allowed'}</div>
            </Col>
            <Col sm={6}>
              <h6>Submitted: {(new Date(order.submitted)).toLocaleString('en-US')}</h6>
              <div style={{maxHeight: '750px', overflowY: 'scroll'}}>
                <Notes orderId={order.id} notes={order.notes} assignments={order.assignments}/>
              </div>
            </Col>
          </Row>
        </CardBody>
      </Card>
    );
  }
}

export default CanceledOrder;
