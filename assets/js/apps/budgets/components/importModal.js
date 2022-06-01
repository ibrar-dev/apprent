import React from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col, Button} from 'reactstrap';
import actions from '../actions';

const scanLine = (line) => {
  const chars = line.split('');
  const {row} = chars.reduce(({row, current, inQuote}, char) => {
    if (char === '"' && inQuote) return {row: row.concat([current]), current: '', inQuote: false};
    if (char === '"') return {row, current: '', inQuote: true};
    if (char === ',' && !inQuote) return {row: row.concat([current]), current: '', inQuote};
    return {row, current: current + char, inQuote};
  }, {row: [], current: ''});
  return row;
};

class ImportModal extends React.Component {
  state = {};

  changeUpload({target: {files: [file]}}) {
    const {toggle, property, year} = this.props;
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result.split('\n');
      result.shift();
      result.shift();
      const lines = [];
      result.forEach((row) => {
        const cells = scanLine(row);
        const accountId = cells[0];
        cells.slice(4).forEach((amount, index) => {
          if (amount.length > 0 && amount !== '\r') {
            lines.push({
              account_id: accountId,
              property_id: property.id,
              month: `${year}-${('0' + (index + 1)).substr(-2)}-01`,
              amount
            })
          }
        });
      });
      actions.saveBudget(lines).then(toggle)
    };
    reader.readAsBinaryString(file);
  }

  render() {
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Import
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <Button outline color="success" onClick={actions.downloadTemplate}>
              Download Template
            </Button>
          </Col>
          <Col>
            <input type="file" onChange={this.changeUpload.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
    </Modal>;
  }
}

export default ImportModal;