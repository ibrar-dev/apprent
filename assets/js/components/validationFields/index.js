import React from 'react';
import {Input} from 'reactstrap';
import Select from '../select';
import DatePicker from '../datePicker';

const validations = new Map();

class ValidatedField extends React.Component {
  constructor(props) {
    super(props);
    this.ref = Symbol();
    validations.set(props.context, {...validations.get(props.context), [this.ref]: this});
    this.state = {isValid: true};
  }

  componentWillUnmount() {
    const context = validations.get(this.props.context);
    delete context[this.ref];
    validations.set(this.props.context, context);
  }

  resetValidate(){
    this.setState({...this.state, isValid: true})
  }

  validate() {
    const {validation, value} = this.props;
    const isValid = validation(value);
    this.setState({isValid});
    return isValid;
  }
}

class ValidatedSelect extends ValidatedField {

  render() {
    const {className, ...props} = this.props;
    const {isValid} = this.state;
    const fullClassName = `${(className || '')} form-control p-0 h-auto border-0 ${(isValid ? '' : 'is-invalid')}`;
    const styles = {
      control(base) {
        return isValid ? base : {...base, borderColor: '#dc3545'};
      }
    };
    return <>
      <Select {...props} className={fullClassName} styles={styles}/>
      <div className="invalid-feedback">{this.props.feedback}</div>
    </>;
  }
}

class ValidatedInput extends ValidatedField {
  render() {
    const {className, mask, context, ...props} = this.props;
    const {isValid} = this.state;
    const Component = mask || Input;
    return <>
      <Component {...props} className={`${(className || '')} ` + (isValid ? '' : 'is-invalid')} validation="true"/>
      <div className="invalid-feedback">{this.props.feedback}</div>
    </>;
  }
}

class CustomDatePickerInput extends React.Component {
  render() {
    const {value, feedback, onChange, onClick, isValid} = this.props;
    return <>
      <Input value={value} onChange={onChange} onClick={onClick} className={isValid ? '' : 'is-invalid'}/>
      <div className="invalid-feedback">{feedback}</div>
    </>;
  }
}

class ValidatedDatePicker extends ValidatedField {
  render() {
    const {className, feedback, ...props} = this.props;
    const {isValid} = this.state;
    return <div>
      <DatePicker {...props} invalid={!isValid}/>
      <div className="invalid-feedback">{feedback}</div>
    </div>
  }
}

const validate = (caller) => {
  const context = validations.get(caller);
  return new Promise((resolve, reject) => {
    const tests = Object.getOwnPropertySymbols(context).map(sym => {
      return context[sym].validate();
    });
    tests.every(v => v) ? resolve() : reject();
  });
};

const resetValidate = (caller) => {
  const context = validations.get(caller);
  return new Promise((resolve, reject) => {
    const tests = Object.getOwnPropertySymbols(context).map(sym => {
      return context[sym].resetValidate();
    });
    tests.every(v => v) ? resolve() : reject();
  });
};

export {ValidatedInput, ValidatedSelect, ValidatedDatePicker, validate, resetValidate};