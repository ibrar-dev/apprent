import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Nav, NavItem, Row, Col, NavLink, Table} from 'reactstrap';
import moment from 'moment';

class InfoModal extends Component {
  state = {
    active: "likes"
  }

  setActive(active) {
    this.setState({...this.state, active: active})
  }

  render() {
    const {toggle, post} = this.props;
    const {active} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader>
        Post from {post.resident}
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm={12}>
            {post.text}
          </Col>
        </Row>
        <Row>
          <Col>
            <Nav tabs>
              <NavItem>
                <NavLink active={active === "likes"} onClick={this.setActive.bind(this, 'likes')}>Likes</NavLink>
              </NavItem>
              <NavItem>
                <NavLink active={active === "reports"} onClick={this.setActive.bind(this, 'reports')}>Reports</NavLink>
              </NavItem>
            </Nav>
          </Col>
        </Row>
        <Row>
          <Col sm={12}>
            <Table hover>
              <thead>
                <tr>
                  <th>Resident</th>
                  <th>Date</th>
                  <th>{active === 'likes' ? '' : 'Report'}</th>
                </tr>
              </thead>
              <tbody>
              {active === 'likes' && post.likes.map(l => {
                return <tr key={l.id}>
                  <td>{l.tenant}</td>
                  <td>{moment.utc(l.inserted_at).local().format("MM/DD/YY HH:mm")}</td>
                </tr>
              })}
              {active === 'reports' && post.reports.map(r => {
                return <tr key={r.id}>
                  <td>{r.reporter || r.admin}</td>
                  <td>{moment.utc(r.inserted_at).local().format("MM/DD/YY HH:mm")}</td>
                  <td>{r.reason}</td>
                </tr>
              })}
              </tbody>
            </Table>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default InfoModal