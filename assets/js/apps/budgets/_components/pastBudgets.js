import React, {Component} from 'react';
import {connect} from "react-redux";
import moment from "moment";
import {Row, Col, Card, CardHeader, CardBody, Input} from 'reactstrap';
import Pagination from '../../../components/pagination';
import Select from "../../../components/select";
import actions from '../actions';
import Account from './account';
import DetailedModal from './detailedModal';

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
]

class PastBudgets extends Component {
  state = {filterVal: ''}

  constructor(props) {
    super(props)
    actions.fetchYears();
  }

  title() {
    const {toggleBox, hidden} = this.props;
    return <span className="cursor-pointer w-75" onClick={toggleBox}><i className={`fas fa-arrow-${hidden ? 'circle-right' : 'circle-left'}`} />{" "}View Other Budgets</span>
  }

  changeYear({target: {value}}) {
    actions.setYear(moment(value).format("YYYY"))
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

  render() {
    const {years, year} = this.props;
    const {detailed} = this.state;
    return <Row className="mt-1">
      <Col>
        <Card>
          <CardHeader className="d-flex justify-content-between">
            {this.title()}
            <Select value={year} placeholder="Select Year" name="year"
                    onChange={this.changeYear.bind(this)}
                    className="flex-fill"
                    options={years.map(y => {
                      return {value: y, label: moment(y).format("YYYY")}
                    })}/>
          </CardHeader>
          {year && <CardBody>
            <Pagination title={`${year}'s Budget`}
                        component={Account}
                        headers={headers}
                        additionalProps={{toggle: this.toggleDetailed.bind(this)}}
                        tableClasses={"table-hover"}
                        filters={this.filters()}
                        field="account"
                        collection={this.filtered()}/>
          </CardBody>}
        </Card>
        {detailed && <DetailedModal toggle={this.toggleDetailed.bind(this, null)} account={detailed} />}
      </Col>
    </Row>
  }
}

export default connect(({years, year, budget}) => {
  return {years, year, budget}
})(PastBudgets)