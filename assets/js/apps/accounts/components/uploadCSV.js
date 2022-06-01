import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalBody, ModalHeader, ModalFooter, Row, Col, Input, Alert} from 'reactstrap';
import actions from '../actions';

class UploadCSV extends React.Component {
  state = {};

  setProperty(e) {
    this.setState({...this.state, property_id: e.target.value});
  }

  setFile(e) {
    this.setState({...this.state, file: e.target.files[0]});
  }

  upload() {
    actions.uploadCSV(this.state).then(r => {
      this.setState({...this.state, response: `${r.data.imported} charges imported`});
    });
  }

  toggleResponse() {
    this.setState({...this.state, response: null});
  }

  render() {
    const {toggle, properties} = this.props;
    const {property_id, response} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Upload Utility Charges
      </ModalHeader>
      <ModalBody>
        {response && <Alert color="success" toggle={this.toggleResponse.bind(this)}>{response}</Alert>}
        <Row>
          <Col sm={6}>
            <Input type="select" value={property_id} onChange={this.setProperty.bind(this)}>
              <option/>
              {properties.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </Input>
          </Col>
          <Col sm={6}>
            <input type="file" onChange={this.setFile.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <button className="btn btn-success" onClick={this.upload.bind(this)}>
          Upload
        </button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({properties}) => {
  return {properties};
})(UploadCSV);