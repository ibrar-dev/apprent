import React, { Component } from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Table} from 'reactstrap';
import {connect} from "react-redux";
import moment from 'moment';
import actions from '../actions';
import canEdit from '../../../components/canEdit';
import snackbar from '../../../components/snackbar';
import confirmation from '../../../components/confirmationModal';

class MaterialLogs extends Component {
  state = {};

  componentWillMount() {
    actions.fetchMaterialInfo(this.props.material.id);
  }

  cancelReturn(log) {
    const log_params = log;
    log_params.returned = null;
    confirmation("Please confirm that you would like to cancel the return and send the material back to the property.").then(() => {
      actions.undoReturn(log.id, log_params);
    })
  }

  returnMaterial(log) {
    if (moment().diff(log.inserted_at, 'days') < 7) {
      confirmation("Please confirm that you would like to cancel the log and return the material back to the stock location.").then(() => {
        actions.returnMaterial(log.id, log);
      })
    } else if (canEdit(["Super Admin", "Regional", "Accountant"])) {
      confirmation("Please confirm that you would like to cancel the log and return the material back to the stock location.").then(() => {
        actions.returnMaterial(log.id, log);
      })
    } else {
      snackbar({message: "Material was sent over 7 days ago. To return this material please contact your regional or an IT admin", args: {type: "error"}})
    }
  }

  refreshMaterial() {
    actions.fetchMaterialInfo(this.props.material.id);
  }

  render() {
    const {material, toggle, materialInfo} = this.props;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader>Logs for {material.name}</ModalHeader>
      <ModalBody>
        <Table>
          <thead>
            <tr>
              <th/>
              <th>Note</th>
            </tr>
          </thead>
          <tbody>
            {materialInfo.logs && materialInfo.logs.map(l => {
              return <tr key={l.id} className={`alert-${l.returned ? 'danger' : ''}`}>
                <td>
                  {!l.returned && canEdit(["Super Admin", "Regional", "Tech", "Accountant", "Admin"]) && <Button onClick={this.returnMaterial.bind(this, l)} outline color="info">Undo</Button>}
                  {l.returned && canEdit(["Super Admin", "Regional"]) && <Button onClick={this.cancelReturn.bind(this, l)} outline color="warning">Cancel</Button>}
                  </td>
                <td>On {moment.utc(l.inserted_at).local().format("YYYY-MM-DD h:MM A")}, <b>{l.quantity}</b> {l.quantity > 1 ? 'were' : 'was'} sent to <b>{l.property}</b>. ${materialInfo.cost * l.quantity} was billed to the property</td>
              </tr>
            })}
          </tbody>
        </Table>
        {materialInfo.logs <= 0 && <div>No Logs Recorded Yet</div>}
      </ModalBody>
      <ModalFooter className="d-flex justify-content-between">
        <span>Viewing {materialInfo.logs && materialInfo.logs.length} logs</span>
        <span>${materialInfo.cost}/Item</span>
        <span><Button outline onClick={this.refreshMaterial.bind(this)} color="info"><i className="fas fa-sync" /></Button></span>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({materialInfo}) => {
  return {materialInfo}
})(MaterialLogs);