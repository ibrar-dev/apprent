import React from 'react';
import Header from './header';

class PaginationTable extends React.Component {
  render() {
    const {headers, list, tableClasses, totalRow, parent} = this.props;
    return <div className="table-responsive-sm">
      <table className={`table m-0 ${tableClasses}`}>
        <thead>
          <tr>
            {headers.map((h, i) => <Header key={i} parent={parent} {...h} />)}
          </tr>
        </thead>
        <tbody>
          {!list.length ? <tr className="text-center mt-3" style={{height: 600}}>
            <th colSpan={headers.length || 1}><h5>No Results Found</h5></th>
          </tr> : null}
          {list.length ? list : null}
          {totalRow ? totalRow : null}
        </tbody>
      </table>
    </div>
  }
}

export default PaginationTable;
