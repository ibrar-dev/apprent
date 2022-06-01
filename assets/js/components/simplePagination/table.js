import React from 'react';
import Header from './header';
import { Table } from 'reactstrap';
class PaginationTable extends React.Component {
  render() {
    const {headers, list, tableClasses} = this.props;
    return <table className={`table ${tableClasses}`} style={{borderCollapse:"separate", borderSpacing:"0 0px", marginTop:"-10px", paddingTop:"10px", width:"100%"}}>
      <thead>
      <tr style={headers.style ? headers.style : {}}>
        {headers.columns && headers.columns.map((h, i) => <Header key={i} parent={this.props.parent} {...h} />)}
      </tr>
      </thead>
      <tbody style={{height:"300px"}}>
        {list}
      </tbody>
    </table>;
  }
}

export default PaginationTable;
