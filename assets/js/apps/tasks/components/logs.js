import React from 'react';
import {Modal, ModalHeader, ModalBody, Table} from 'reactstrap';

class Logs extends React.Component {
  state = {};

  render() {
    const {toggle, logs} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Logs</ModalHeader>
      <ModalBody>
        <Table striped>
          <tbody>
          {logs.map((log, i) => <tr key={i}>
            <td>
              {log}
            </td>
            </tr>
          )}
          </tbody>
        </Table>
      </ModalBody>
    </Modal>;
  }
}

export default Logs;