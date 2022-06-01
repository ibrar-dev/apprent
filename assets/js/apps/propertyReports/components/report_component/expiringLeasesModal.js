import React, {Component} from 'react';
import {Modal, ModalHeader, ModalFooter, ModalBody, Table} from 'reactstrap';
import Pagination from '../../../../components/pagination';
import moment from 'moment';

const headers = [
  {label: 'Unit', sort: 'unit'},
  {label: 'Lease Expiring', sort: 'end_date'},
  {label: 'Days Until', sort: (p1, p2) => moment(p1.end_date).diff(moment()) > moment(p2.end_date).diff(moment()) ? 1 : -1},
  {label: 'Lease Start', sort: 'start_date'},
  {label: 'Move In', sort: 'actual_move_in'}
];

const TableRow = ({row}) => {
  return <tr>
    <td>{row.unit}</td>
    <td>{moment(row.end_date).format("MM/DD/YY")}</td>
    <td>{moment(row.end_date).fromNow(true)}</td>
    <td>{moment(row.start_date).format("MM/DD/YY")}</td>
    <td>{moment(row.actual_move_in).format("MM/DD/YY")}</td>
  </tr>
}

class ExpiringLeasesModal extends Component {
  state = {}

  render() {
    const {data, toggle, title} = this.props;
    const {units} = data;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalBody>
        <Pagination collection={units}
                    title={title}
                    field="row"
                    component={TableRow}
                    headers={headers} />
      </ModalBody>
    </Modal>
  }
}

export default ExpiringLeasesModal;