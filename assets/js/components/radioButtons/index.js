import React from 'react';
import {Button, ButtonGroup} from 'reactstrap';

class RadioButtons extends React.Component {
  setSelected(value) {
    this.props.onChange({target: {name: this.props.name, value}})
  }

  render() {
    const {options, color, value} = this.props;
    return <ButtonGroup>
      {options.map((option, index) => {
        return <Button key={index} color={color || 'success'} outline={value !== option.value}
                       onClick={this.setSelected.bind(this, option.value)}>
          {option.label}
        </Button>
      })}
    </ButtonGroup>;
  }
}

export default RadioButtons;