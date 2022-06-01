import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import Employment from '../models/employment';
import utils from './utils';

class IncomeForm extends React.Component {
  editField({target: {name, value}}) {
    actions.setApplicationField('income', name, value);
  }

  removeIncome() {
    actions.setApplicationField('income', 'present', false)
  }

  render() {
    const userField = utils.userField.bind(this, this.props.income);
    const {lang} = this.props;
    return <div className="card">
      <div className="card-header">
        Other Income
        <a className="delete-button" onClick={this.removeIncome}>
          <i className="fas fa-trash"/>
        </a>
      </div>
      <div className="card-body">
        {userField('description', lang.description)}
        {userField('salary', lang.monthly_income, 'number')}
      </div>
    </div>
  }
}

class EmploymentForm extends React.Component {
  editField(e) {
    actions.editCollection('employments', this.props.index, e.target.name, e.target.value);
  }

  render() {
    const {employment, index, occupantOptions, lang} = this.props;
    const userField = utils.userField.bind(this, employment);
    return <div className="card">
      <div className="card-header">
        {lang.employment_info}
      </div>
      <div className="card-body">
        <div className="mb-4">
          {userField('occupant_index', lang.occupant, 'select', {options: occupantOptions})}
        </div>
        {userField('employer', lang.employer)}
        {userField('address', lang.address, 'address')}
        {userField('phone', lang.phoneNumber, 'phone')}
        {userField('email', lang.email)}
        {userField('supervisor', lang.supervisor_name)}
        {userField('duration', lang.employment_duration)}
        {userField('salary', lang.monthly_income, 'number')}
      </div>
    </div>
  }
}

class Employments extends React.Component {
  addIncome() {
    actions.setApplicationField('income', 'present', true)
  }

  render() {
    const {employments, income, occupants} = this.props.application;
    const {lang} = this.props;
    const leaseHolders = occupants.filter(o => o._data.status === "Lease Holder")
    const occupantOptions = leaseHolders.map((o, index) => {
      return {value: index + 1, label: `#${index + 1} ${o.full_name}`}
    });
    return <div>
      {employments.map((employment, index) => {
        return <EmploymentForm key={employment._id}
                               index={index}
                               lang={lang}
                               occupantOptions={occupantOptions}
                               employment={employment}/>;
      })}
      {income.present && <IncomeForm income={income} lang={lang}/>}
      {!income.present && <div className="add-button" onClick={this.addIncome}>
        <button>
          <i className="fas fa-plus"/>
        </button>
        {lang.other_income}
      </div>}
    </div>;

  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Employments);
