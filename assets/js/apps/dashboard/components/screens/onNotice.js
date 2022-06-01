import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import Pagination from "../../../../components/simplePagination";

class Notice extends Component {
  render() {
    const {notice} = this.props;
    return <tr  className="link-row"  >
      <td className="align-middle">
        {`${notice.unit.property.name} - ${notice.unit.number}`}
      </td>
      <td className="align-middle">
        {notice.tenant.name}
      </td>
      <td className="align-middle">
        {notice.move_out_date}
      </td>
      <td className="align-middle">
        {notice.move_out_reason}
      </td>
      <td className="align-middle">
        {notice.end_date}
      </td>
    </tr>
  }
}

class PartsPending extends Component {
  state = {}

  headers = {columns: [
      {label: 'Unit', min: true},
      {label: 'Name', min: true},
      {label: 'Expected Move Out', sort: 'move_out_date'},
      {label: 'Reason', sort: 'reason'},
      {label: 'End Date', sort: 'name'}
    ], style: {color: '#7d7d7d'}};


  render() {
    const {info} = this.props;
    return <Fragment>
      <ModalHeader>
        On Notice
      </ModalHeader>
      <ModalBody>
        <Pagination
            title="On Notice"
            collection={info}
            component={Notice}
            headers={this.headers}
            field="notice"
            hover={true}
        />
      </ModalBody>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.resident_info.on_notice};
})(PartsPending);