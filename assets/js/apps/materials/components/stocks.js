import React from 'react';
import {connect} from 'react-redux';
import {withRouter} from 'react-router';
import NewStock from './newStock';
import Stock from './stock';
import Pagination from '../../../components/pagination';

class Stocks extends React.Component {
  state = {};
  headers = [
    {label: 'Inventory', sort: null, min: true},
    {label: 'Image', sort: null, min: true},
    {label: 'Name', sort: 'name'},
    {label: 'Properties', sort: null},
    {label: '', sort: null}
  ];

  newStock() {
    this.setState({...this.state, modal: !this.state.modal});
  }

  filterChange(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  printStock(stockId) {
    this.setState({...this.state, printing: stockId});
    setTimeout(() => {
      this.setState({...this.state, printing: null});
    }, 5000);
  }

  render() {
    const {stocks, properties} = this.props;
    const {modal, filterVal, printing} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <React.Fragment>
      <Pagination title="Stocks"
                  collection={stocks.filter(s => filter.test(s.name))}
                  component={Stock}
                  filters={<input className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                  headers={this.headers}
                  additionalProps={{printStock: this.printStock.bind(this)}}
                  field="stock">
      </Pagination>
      <button className="btn btn-success" onClick={this.newStock.bind(this)}>
        Create New
      </button>
      {modal && <NewStock properties={properties} close={this.newStock.bind(this)}/>}
      {printing && <iframe style={{width: 0, height: 0}} src={`/stocks/${printing}/print`} />}
    </React.Fragment>;
  }
}

export default withRouter(connect(({stocks, filter, properties}) => {
  return {stocks, filter, properties}
})(Stocks));
