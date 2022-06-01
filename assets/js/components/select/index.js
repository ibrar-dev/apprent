import React from 'react';
import Select from 'react-select';
import Creatable from 'react-select/creatable';

const styles = {
  menu(b) {
    return {...b, zIndex: 100}
  },
  control(b) {
    return {...b, minHeight: 34}
  }
};
const theme = (t) => {
  return {...t, spacing: {...t.spacing, baseUnit: 3, controlHeight: 34}};
};

class MySelect extends React.Component {
  onChange(option) {
    let value;
    if (this.props.multi) {
      value = option ? option.map(o => o.value) : [];
    } else {
      value = (option || {value: null}).value;
    }
    this.props.onChange({target: {name: this.props.name, value}});
  }

  selectedOptions(opts) {
    const {value, options, multi} = this.props;
    const optionList = opts || options;
    if (multi) {
      return optionList.reduce((s, o) => {
        return (value || []).some(v => v === o.value) ? s.concat([o]) : s
      }, []);
    }
    if (optionList.length && optionList[0].options) {
      let val = null;
      optionList.find(o => {
        val = this.selectedOptions(o.options);
        return val;
      });
      return val;
    }
    return (opts || options).find(o => o.value === value);
  }

  render() {
    const {multi, creatable, disabled, autoFocus, onKeyPress, innerRef, className} = this.props;
    styles.container = (s) => {
      return {...s, pointerEvents: disabled ? 'none' : ''}
    };
    const Component = creatable ? Creatable : Select;
    return <Component {...this.props}
                      isMulti={multi}
                      autoFocus={autoFocus}
                      ref={innerRef}
                      onKeyDown={onKeyPress}
                      styles={{
                        ...styles,
                        ...this.props.styles,
                        control: (base, state) => ({
                          ...base,
                          border: className && className.includes("disabled-input") ? '1px solid transparent' : '1px solid #e4e6eb',
                          '&:hover': {borderColor: '#cccccc'},
                          boxShadow: state.isFocused && " 0 0 0 1px #cccccc"
                        })
                      }}
                      theme={theme}
                      onChange={this.onChange.bind(this)}
                      value={this.selectedOptions() || ""}/>
  }
}

export default MySelect;
