import React from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col} from 'reactstrap';
import actions from '../actions';

class NewStock extends React.Component {
  state = {name: '', propertyIds: []};

  propertyIds(e) {
    let {propertyIds} = this.state;
    const value = parseInt(e.target.value);
    if (e.target.checked) {
      propertyIds.push(value);
    }
    else {
      propertyIds = propertyIds.filter(p => p !== value);
    }
    this.setState({...this.state, propertyIds});
  }

  changeName(e) {
    this.setState({...this.state, name: e.target.value});
  }

  create() {
    actions.createStock(this.state).then(this.props.close);
  }

  render() {
    const {properties, close} = this.props;
    properties.sort((a, b) => a.name < b.name ? -1 : 1);
    const {name, propertyIds} = this.state;
    return <Modal isOpen={true}>
      <ModalHeader toggle={close}>
        Create New Stock
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm={3}>
            Name
          </Col>
          <Col sm={9}>
            <input className="form-control" name="name" value={name} onChange={this.changeName.bind(this)}/>
          </Col>
        </Row>
        <Row>
          <Col sm={3}>
            Properties
          </Col>
          <Col sm={9}>
            <ul className="list-unstyled">
              {properties.map(p => {
                return <li key={p.id}>
                  <label>
                    <input value={p.id}
                           type="checkbox"
                           checked={propertyIds.indexOf(p.id) > -1}
                           onChange={this.propertyIds.bind(this)}/>
                    {' '}{p.name}
                  </label>
                </li>
              })}
            </ul>
          </Col>
        </Row>
        <Row>
          <Col sm={3}/>
          <Col sm={9}>
            <button className="btn btn-success btn-block" onClick={this.create.bind(this)}>
              Create
            </button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default NewStock;