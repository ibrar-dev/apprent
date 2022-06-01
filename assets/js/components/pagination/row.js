import React from 'react';
import {Row} from 'reactstrap';

class PaginationRow extends React.Component {
  render() {
    const {list, tableClasses, totalRow} = this.props;
    return <Row className={tableClasses || ''}>
      {list}
      {totalRow ? totalRow : null}
    </Row>;
  }
}

export default PaginationRow;