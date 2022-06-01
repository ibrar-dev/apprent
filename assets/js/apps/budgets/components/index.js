import React from 'react';
import {connect} from "react-redux";
import {Button} from "reactstrap";
import BudgetLine from './budgetLine';
import ImportModal from './importModal';
import Pagination from '../../../components/pagination';
import actions from "../actions";
import PropertySelect from "../../../components/propertySelect";
import Select from "../../../components/select";

const headers = [
  {label: "Account", min: true, sort: 'num'},
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

const currentYear = (new Date()).getUTCFullYear();
const years = [currentYear];
for (let i = 1; i <= 20; i++) {
  years.push(currentYear - i);
}

const budgetChanges = new Map();

class BudgetsApp extends React.Component {
  state = {};

  setYear({target: {value}}) {
    actions.setYear(value);
  }

  saveBudget() {
    const {property, year} = this.props;
    const params = [];
    budgetChanges.forEach((amount, line) => {
      params.push({
        account_id: line.id,
        property_id: property.id,
        month: `${year}-${('0' + line.month).substr(-2)}-01`,
        amount: parseFloat(amount)
      })
    });
    actions.saveBudget(params).then(() => {
      this.toggleEditMode();
      budgetChanges.clear();
    })
  }

  toggleEditMode(save) {
    const {editMode} = this.state;
    if (editMode && save) {
      this.saveBudget();
    } else {
      this.setState({editMode: !this.state.editMode});
    }
  }

  toggleImport() {
    this.setState({importMode: !this.state.importMode});
  }

  changeValue(budgetLine, newAmount) {
    budgetChanges.set(budgetLine, newAmount);
  }

  render() {
    const {properties, property, budget, year} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    if (!property) return <div/>;
    const {editMode, importMode} = this.state;
    const toggleEdit = this.toggleEditMode.bind(this, true);
    const toggleImport = this.toggleImport.bind(this);
    return <>
      <Pagination headers={headers}
                  toggleIndex
                  tableClasses={'sticky-header ' + (editMode ? 'table-sm' : '')}
                  headerClassName="p-0"
                  additionalProps={{toggleEdit, editMode, year, parent: this, changeValue: this.changeValue}}
                  collection={budget}
                  field="budgetLine"
                  filters={<div className="d-flex align-items-center" style={{width: 250}}>
                    {!editMode && <Button color="success" size="sm" onClick={toggleImport} outline className="mr-2">
                      Import
                    </Button>}
                    {editMode && <Button color="danger" size="sm" onClick={this.toggleEditMode.bind(this, false)}
                                         outline className="mr-2">
                      Cancel
                    </Button>}
                    <Button color="info" size="sm" onClick={toggleEdit} outline className="mr-2">
                      {editMode ? 'Save' : 'Edit'}
                    </Button>
                    <div className="flex-auto">
                      <Select options={years.map(y => ({label: y, value: y}))} name="year" value={year}
                              disabled={editMode} onChange={this.setYear.bind(this)}/>
                    </div>
                  </div>}
                  title={<PropertySelect property={property} properties={properties}
                                         onChange={actions.viewProperty}/>}
                  component={BudgetLine}
      />
      {importMode && <ImportModal property={property} year={year} toggle={toggleImport}/>}
    </>;
  }
}

export default connect(({properties, property, budget, year}) => {
  return {properties, property, budget, year}
})(BudgetsApp)
