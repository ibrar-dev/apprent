import React, {Component} from 'react';
import {Row, Col, Card, Nav, NavItem, NavLink} from 'reactstrap';

class Selector extends Component {
  state = {
    active: 'report'
  }

  setActive(type) {
    this.setState({...this.state, active: type})
  }

  render() {
    return <Row>
      <Col>
        <Card body>
          <Nav></Nav>
        </Card>
      </Col>
    </Row>
  }
}

export default Selector;