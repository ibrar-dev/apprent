import React from 'react';
import {withRouter} from 'react-router';
import moment from 'moment';
import {Card, CardHeader, CardBody, CardFooter, Button, Row, Col, Table, Input, ButtonGroup} from 'reactstrap';
import {validate, ValidatedInput, ValidatedDatePicker} from '../../../components/validationFields';
import CheckBox from '../../../components/fancyCheck';
import Entry from './entry';
import actions from '../actions';
import {connect} from "react-redux";
import {toCurr} from '../../../utils'


class PageForm extends React.Component {
  state = {page: {date: moment(), cash: true, accrual: true, entries: [{_id: 1, amount: null}, {_id: 2, amount: null}], ...this.props.page}};

  change({target: {name, value}}) {
    this.setState({page: {...this.state.page, [name]: value}});
  }

  changeBook({target: {name, checked}}) {
    const page = {...this.state.page, [name]: checked};
    if (page.cash || page.accrual) this.setState({page});
  }

  changeEntry(index, {target: {name, value}}) {
    const {page} = this.state;
    page.entries[index] = {...page.entries[index], [name]: value};
    this.setState({page});
  }

  newEntry() {
    const {page} = this.state;
    const newId = page.entries.reduce((max, e) => (e.id || e._id) > max ? (e.id || e._id) : max, 0) + 1;
    page.entries.push({_id: newId});
    this.setState({page});
  }

  toggleEntryType(index, type) {
    this.state.page.entries[index].is_credit = type === 'credit';
    this.changeEntry(index, {target: {name: 'is_credit', value: this.state.page.entries[index].is_credit}})
  }

  deleteEntry(index) {
    const {page} = this.state;
    page.entries.splice(index, 1);
    this.setState({page});
  }

  save() {
    validate(this).then(() => {
      const {page} = this.state;
      const func = page.id ? 'updatePage' : 'createPage';
      actions[func](page).then(this.props.toggle);
    }).catch(() => {
    });
  }

  saveAndNew() {
    validate(this).then(() => {
      const {page} = this.state;
      const func = page.id ? 'updatePage' : 'createPage';
      actions[func](page).then(() => {
        this.setState({page: {date: moment(), cash: true, accrual: true, entries: [], name: ''}});
        this.newEntry();
        this.newEntry();
      })
    }).catch(() => {
    });
  }

  goBack() {
    const {history, toggle} = this.props;
    const {page} = this.state;
    page.id ? history.push(`/journal_entries`, {}) : toggle();
  }

  render() {
    const {page} = this.state;
    const propertyTotals = {};
    const entryTotals = page.entries.reduce((sum, e) => {
      if(e.property_id && e.amount){
        if(!propertyTotals[e.property_id]) propertyTotals[e.property_id] = {credit: 0, debit: 0}
        e.is_credit ? propertyTotals[e.property_id].credit += parseFloat(e.amount) : propertyTotals[e.property_id].debit += parseFloat(e.amount);
      }
      e.is_credit ? sum.credit += parseFloat(e.amount) || 0 : sum.debit += parseFloat(e.amount) || 0;
      return sum;
    }, {credit: 0, debit: 0});
    return <Card>
      <CardHeader className="d-flex align-items-center justify-content-between">
        {page.id ? 'Edit Entry' : 'New Entry'}
        <Button onClick={this.goBack.bind(this)} color="danger" size="sm">
          <i className="fas fa-arrow-circle-left"/> Back
        </Button>
      </CardHeader>
      <CardBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center"><b>Date</b></Col>
          <Col sm={9}>
            <ValidatedDatePicker context={this}
                                 validation={(d) => !!d}
                                 feedback="Please select a date"
                                 value={page.date}
                                 name="date"
                                 onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center"><b>Book</b></Col>
          <Col sm={9} className="d-flex align-items-center">
            <label className="mr-4 mb-0 d-flex align-items-center">
              <CheckBox checked={page.cash} name="cash" onChange={this.changeBook.bind(this)}/>
              <div className="ml-1">Cash</div>
            </label>
            <label className="m-0 d-flex align-items-center">
              <CheckBox checked={page.accrual} name="accrual" onChange={this.changeBook.bind(this)}/>
              <div className="ml-1">Accrual</div>
            </label>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center"><b>Notes</b></Col>
          <Col sm={9}>
            <ValidatedInput context={this}
                            type="textarea"
                            rows={3}
                            validation={(d) => !!d}
                            feedback="Please enter a description"
                            value={page.name}
                            name="name"
                            onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row>
          <Table>
            <thead>
            <tr>
              <th className="min-width">
                <a onClick={this.newEntry.bind(this)}>
                  <i className="fas fa-plus-circle fa-2x text-success"/>
                </a>
              </th>
              <th className="align-middle" style={{width: 250}}>Property</th>
              <th className="align-middle" style={{width: 250}}>Account</th>
              <th className="align-middle">Debit</th>
              <th className="align-middle">Credit</th>
            </tr>
            </thead>
            <tbody>
            {page.entries.map((entry, index) => {
              return <Entry key={entry.id || entry._id}
                            entry={entry}
                            parent={this}
                            index={index}
                            addEntry={this.newEntry.bind(this)}
                            canDelete={page.entries.length > 1}/>;
            })}
            {propertyTotals && Object.keys(propertyTotals).map((pt) => {
              const property = this.props.properties.find((p) => p.id == pt);
              return <tr key={pt}>
                <td colSpan={3} className="text-right align-middle">
                  <strong>{property.name} Total:</strong>
                </td>
                <td>
                  <ValidatedInput context={this}
                                  validation={() => propertyTotals[pt].credit.toFixed(2) == propertyTotals[pt].debit.toFixed(2)}
                                  feedback="Properties credit and debit must equal"
                                  name={`${pt}_amount`}
                                  className="text-right"
                                  style={{backgroundColor: "transparent", border: "none", fontWeight: 700}}
                                  value={toCurr(propertyTotals[pt].debit)}
                                  disabled={true}/>
                </td>
                <td>
                  <Input style={{backgroundColor: "transparent", border: "none", fontWeight: 700}}
                         className="text-right"
                         value={toCurr(propertyTotals[pt].credit)}
                         disabled={true}/>
                </td>
              </tr>;
            })}
            <tr>
              <td colSpan={3} className="text-right align-middle">
                <strong>Total:</strong>
              </td>
              <td>
                <ValidatedInput context={this}
                                validation={(t) => t === 0}
                                validation={() => entryTotals.debit.toFixed(2) == entryTotals.credit.toFixed(2)}
                                feedback="Line items must equal 0 for each property"
                                name="amount"
                                className="p-0 bg-transparent border-0 h-auto font-weight-bold text-right"
                                value={isNaN(entryTotals.debit) ? '' : toCurr(entryTotals.debit)}
                                disabled={true}/>
              </td>
              <td>
                <Input className="p-0 bg-transparent border-0 h-auto font-weight-bold text-right"
                       value={isNaN(entryTotals.credit) ? '' : toCurr(entryTotals.credit)}
                       disabled={true}/>
              </td>
            </tr>
            </tbody>
          </Table>
        </Row>
      </CardBody>
      <CardFooter className="d-flex justify-content-between">
        <div />
        <ButtonGroup className={"w-50"}>
          <Button color={"success"} outline onClick={this.save.bind(this)}>
            Save
          </Button>
          <Button color={"success"} outline onClick={this.saveAndNew.bind(this)}>
            Save and New Entry
          </Button>
        </ButtonGroup>
        <a onClick={this.newEntry.bind(this)}>
          <i className="fas fa-plus-circle fa-2x text-success"/>
        </a>
      </CardFooter>
    </Card>
  }
}

export default withRouter(connect(({properties}) => {
  return {properties};
})(PageForm));
