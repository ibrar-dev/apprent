import React, {Component} from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Row, Col, Input} from "reactstrap";
import Pagination from '../../../components/pagination';
import actions from '../actions';
import DetailedModal from './detailedModal';
import Account from './account';

const headers = [
  {label: "Number", min: true, sort: 'num'},
  {label: "Name", min: true, sort: 'name'},
  {label: "Account Total", min: true},
  {label: "Jan", min: true},
  {label: "Feb", min: true},
  {label: "March", min: true},
  {label: "April", min: true},
  {label: "May", min: true},
  {label: "June", min: true},
  {label: "July", min: true},
  {label: "August", min: true},
  {label: "Sept", min: true},
  {label: "Oct", min: true},
  {label: "Nov", min: true},
  {label: "Dec", min: true}
];

class ViewBudgets extends Component {
  state = {filterVal: ''};

  constructor(props) {
    super(props);
    actions.setYear(moment().get('year'))
  }

  filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)} style={{width: "100%"}}/>
  }

  changeFilter({target: {value}}) {
    this.setState({...this.state, filterVal: value});
  }

  filtered() {
    const {budget} = this.props;
    const {filterVal} = this.state;
    const regex = new RegExp(filterVal, 'i');
    return budget.filter(a => {
      return a.name.match(regex)
      // Put below line back in once all accounts have numbers and it is no longer optional
      // return (a.name.match(regex) || (a.num && (a.num.match(regex))))
    })
  }

  toggleDetailed(detailed) {
    if (!detailed) actions.clearDetailedAccount();
    this.setState({...this.state, detailed: detailed})
  }

  title() {
    const {toggleBox, hidden} = this.props;
    return <span className="cursor-pointer" onClick={toggleBox}>
      <i className={`fas fa-arrow-${hidden ? 'circle-right' : 'circle-left'}`}/>{" "}{`${moment().get('year')} Budget`}
    </span>
  }

  render() {
    const {detailed} = this.state;
    return <div className="mt-1">
      <Pagination title={this.title()}
                  component={Account}
                  headers={headers}
                  keyFunc={account => account.num}
                  additionalProps={{toggle: this.toggleDetailed.bind(this)}}
                  tableClasses={"table-hover"}
                  filters={this.filters()}
                  field="account"
                  collection={this.filtered()}/>
      {detailed && <DetailedModal toggle={this.toggleDetailed.bind(this, null)} account={detailed}/>}
    </div>;
  }
}

export default connect(({budget}) => {
  return {budget}
})(ViewBudgets)
