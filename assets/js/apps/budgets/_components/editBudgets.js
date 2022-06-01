import React, {Component} from 'react';
import {connect} from "react-redux";
import {Row, Col, Card, CardHeader, CardBody, Input, Modal, ModalHeader, ModalBody, Button} from 'reactstrap';
import Select from '../../../components/select';
import Pagination from '../../../components/pagination';
import confirmation from '../../../components/confirmationModal';
import actions from "../actions";
import moment from "moment";
import Account from "./account";
import EditAccount from "./editAccount";

const headers = [
  {label: "", min: true},
  {label: "Number", min: true, sort: 'num'},
  {label: "Name", min: true, sort: 'name'},
  {label: "Total", min: true},
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

class MonthsModal extends Component {
  closeMonth(m) {
    let month = m.format("YYYY-MM-DD");
    confirmation(`'Please confirm you would like to close the budget for ${m.format("MMMM YYYY")}`).then(() => {
      actions.closeMonth(month);
    })
  }

  render() {
    const {toggle, year} = this.props;
    return <Modal size="lg" toggle={toggle} isOpen={true}>
      <ModalHeader>
        Lock Individual Months for {year}
      </ModalHeader>
      <ModalBody>
        <Row>
          {Array(12).fill().map((_, i) => {
            const month = moment().set('year', year).startOf('year').add(i, 'M')
            return <Col key={i} lg={4}>
                <Button onClick={this.closeMonth.bind(this, month)} outline color="success" block className="m-1">
                  {month.format("MMMM YYYY")}
                </Button>
            </Col>
          })}
        </Row>
      </ModalBody>
    </Modal>
  }
}

class EditBudgets extends Component {
  state = {}

  constructor(props) {
    super(props)
    actions.fetchYears();
  }

  title() {
    const {toggleBox, hidden} = this.props;
    return <span className="cursor-pointer w-75" onClick={toggleBox}><i
      className={`fas fa-arrow-${hidden ? 'circle-right' : 'circle-left'}`}/>{" "}View Other Budgets</span>
  }

  changeYear({target: {value}}) {
    actions.setYear(moment(value).format("YYYY"))
  }

  toggleDetailed(detailed) {
    this.setState({...this.state, detailed: detailed})
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

  closeYear() {
    const {year, property} = this.props;
    confirmation('Please confirm that you would like to lock the entire year.').then(() => {
      actions.closeYear(year, property.id);
    })
  }

  toggleMonthsModal() {
    this.setState({...this.state, monthsModal: !this.state.monthsModal})
  }

  render() {
    const {years, year} = this.props;
    const {detailed, monthsModal} = this.state;
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
          <CardBody>
            <Pagination title={`${year}'s Budget`}
                        component={Account}
                        headers={headers}
                        additionalProps={{toggle: this.toggleDetailed.bind(this), edit: true}}
                        tableClasses={"table-hover"}
                        filters={this.filters()}
                        menu={[
                          {title: 'Lock Entire Year', onClick: this.closeYear.bind(this)},
                          {title: 'Lock Individual Months', onClick: this.toggleMonthsModal.bind(this)}
                        ]}
                        field="account"
                        collection={this.filtered()}/>
          </CardBody>
        </Card>
        {detailed && <EditAccount toggle={this.toggleDetailed.bind(this, null)} account={detailed}/>}
        {monthsModal && <MonthsModal toggle={this.toggleMonthsModal.bind(this)} year={year} />}
      </Col>
    </Row>
  }
}

export default connect(({years, year, budget, property}) => {
  return {years, year, budget, property}
})(EditBudgets)