import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Card, CardHeader, CardBody, CardFooter} from 'reactstrap';
import TabbedBox from '../../../components/tabbedBox';
import PropertySelect from '../../../components/propertySelect';
import canEdit from '../../../components/canEdit';
import actions from "../actions";
import ViewBudgets from './viewBudgets.js';
import PastBudgets from './pastBudgets.js';
import EditBudgets from './editBudgets.js';
import NewBudget from './newBudget.js';
import BudgetReports from './budgetReports.js';

const links = () => {
  let array = [
    {icon: false, data: ViewBudgets, label: 'Current Budget', id: 0},
    {icon: false, data: PastBudgets, label: 'Other Budgets', id: 1},
    {icon: false, data: BudgetReports, label: 'Reports', id: 2}
  ];
  if (canEdit(["Super Admin", "Accountant"])) array.push({
    icon: false,
    data: EditBudgets,
    label: 'Edit Budgets',
    id: 3
  });
  if (canEdit(["Super Admin"])) array.push({icon: false, data: NewBudget, label: 'Imports', id: 4});
  return array
};

class BudgetsApp extends Component {
  state = {mode: links()[0], hidden: false};

  setTab(mode) {
    this.setState({mode})
  }

  toggleBox() {
    this.setState({...this.state, hidden: !this.state.hidden})
  }

  render() {
    const {properties, property} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {mode, hidden} = this.state;
    return <Card>
      <CardHeader className="d-flex">
        <PropertySelect property={property} properties={properties} onChange={actions.viewProperty}/>
      </CardHeader>
      <TabbedBox links={links()} active={mode.id} hidden={hidden} onNavigate={this.setTab.bind(this)}>
        <div className="ml-3">
          <mode.data back={this.setTab.bind(this, links[0])} toggleBox={this.toggleBox.bind(this)} hidden={hidden}/>
        </div>
      </TabbedBox>
    </Card>;
  }
}

export default connect(({properties, property}) => {
  return {properties, property}
})(BudgetsApp)
