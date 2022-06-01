import React from 'react';

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

class RangeSlider extends React.Component {
  constructor(props) {
    super(props);
    this.root = React.createRef();
    this.moveHandler = this.move.bind(this);
    this.dropHandler = this.handleDrop.bind(this);
  }

  componentDidMount() {
    this.range = this.root.current.offsetWidth - 20;
  }

  positionFromValue() {
    const {min, max, step, value} = this.props;
    const numSteps = (max - min) / step;
    const percentage = (((value - min) / step) / numSteps);
    return Math.round(this.range * percentage) + 10;
  }

  valueFromPosition(pos) {
    const {min, max, step} = this.props;
    const rect = this.root.current.getBoundingClientRect();
    const offset = pos - rect.x;
    const percentage = clamp(offset / rect.width, 0, 1);
    const baseVal = step * Math.round(percentage * (max - min) / step);
    return clamp(baseVal + min, min, max);
  }

  handleDrag(e) {
    this.move(e);
    document.addEventListener('mousemove', this.moveHandler);
    document.addEventListener('mouseup', this.dropHandler);
  }

  handleDrop() {
    document.removeEventListener('mousemove', this.moveHandler);
    document.removeEventListener('mouseup', this.dropHandler);
  }

  move(event) {
    const {value, onChange} = this.props;
    const newVal = this.valueFromPosition(event.pageX);
    if (value !== newVal) onChange(newVal);
  }

  render() {
    const position = this.positionFromValue();
    return <div className="rangeslider rangeslider-horizontal" onMouseDown={this.handleDrag.bind(this)} ref={this.root}>
      <div className="rangeslider__fill" style={{width: position || 10}}/>
      <div className="rangeslider__handle" tabIndex="0" style={{left: position || 10}}>
        <div className="rangeslider__handle-label"/>
      </div>
      <ul className="rangeslider__labels"/>
    </div>
  }
}

export default RangeSlider;