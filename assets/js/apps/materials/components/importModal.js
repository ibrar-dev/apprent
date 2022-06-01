import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button} from 'reactstrap';
import actions from '../actions';

class ImportModal extends React.Component {
  state = {};

  csvNameChange(e) {
    this.setState({...this.state, csvName: e.target.value});
  }

  importCSV() {
    const {csvName} = this.state;
    const {stockId, toggle} = this.props;
    this.setState({...this.state, loading: true});
    actions.importCSV(csvName, stockId).then(() => {
      this.setState({...this.state, loading: false});
      alert('Import Successful');
      toggle();
    }).catch(() => {
      this.setState({...this.state, loading: false});
      alert('Something went wrong, import failed.');
    });
  }

  render() {
    const {csvName, loading} = this.state;
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader>
        Import CSV
      </ModalHeader>
      {!loading && <ModalBody>
        <h4>Enter CSV file name:</h4>
        <Input value={csvName} onChange={this.csvNameChange.bind(this)} />
      </ModalBody>}
      {loading && <ModalBody>
        <h4 className="text-center">
          <i className="fas fa-spin fa-circle-o-notch" />
          Importing...
        </h4>
      </ModalBody>}
      <ModalFooter>
        <Button onClick={toggle} color="danger" className="mr-3">Cancel</Button>
        <Button onClick={this.importCSV.bind(this)} color="success">Import</Button>
      </ModalFooter>
    </Modal>
  }
}

export default ImportModal;