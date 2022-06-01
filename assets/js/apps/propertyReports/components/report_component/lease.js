import React, {Component} from "react";
import {Modal, Card, CardHeader, CardBody, Row, Col} from "reactstrap";

class Lease extends Component {
  leaseDates(type) {
    if (type === "Moved In" || type === "Moved Out" || type === "Renewal" || type === "Onsite-Transfer") {
      return <React.Fragment>
        <Col style={{fontWeight: 800}}>Rent Amount</Col>
        {type === "Moved In" && <Col style={{fontWeight: 800}}>Move In</Col>}
        {type === "Moved Out" && <Col style={{fontWeight: 800}}>Move Out</Col>}
        {(type === "Renewal" || type === "Onsite-Transfer") && <Col style={{fontWeight: 800}}>Lease Start</Col>}
        {(type === "Renewal" || type === "Onsite-Transfer") && <Col style={{fontWeight: 800}}>Lease End</Col>}
      </React.Fragment>
    } else if (type === "Month To Month") {
      return <React.Fragment>
        <Col style={{fontWeight: 800}}>Rent Amount</Col>
        <Col style={{fontWeight: 800}}>Lease End</Col>
      </React.Fragment>
    } else {
      return <React.Fragment>
        {/*<Col style={{fontWeight: 800}}>Rent Amount</Col>*/}
        <Col style={{fontWeight: 800}}>{type}</Col>
      </React.Fragment>
    }
  }

  render(){
    const {modal, leases, type} = this.props;
    const items = this.props.getData ? this.props.getData(leases) : null;
    return <Modal className="modal-lg" isOpen={modal} toggle={this.props.toggle}>
      <Card>
        <CardHeader>{type}</CardHeader>
        <CardBody>
            <Row>
              <Col style={{fontWeight: 800}}>Unit</Col>
              <Col style={{fontWeight: 800}}>Resident</Col>
              <Col style={{fontWeight: 800}}>Floor Plan</Col>
              {/*<Col style={{fontWeight: 800}}>Rent Amount</Col>*/}
              {this.leaseDates(type)}
            </Row>
            {items}
        </CardBody>
      </Card>
    </Modal>
  }
}

export default Lease;