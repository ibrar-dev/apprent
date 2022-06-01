import React from 'react';
import Header from './header';

class PaginationTable extends React.Component {
  render() {
    const {headers, list} = this.props;
    return <table className="table" style={{borderCollapse:"separate", borderSpacing:"0 0px", marginTop:"-10px", paddingTop:"10px", width:"100%"}}>
      <thead>
      <tr style={{color:"#5099db"}}>
        {headers.map((h, i) => <Header key={i} parent={this.props.parent} {...h} />)}
      </tr>
      </thead>
      <tbody>
      {list}
      </tbody>
    </table>;
  }
}

export default PaginationTable;