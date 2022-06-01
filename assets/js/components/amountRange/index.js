import {Col, Input, Row, InputGroup} from 'reactstrap';
import React from 'react'
import {debounce} from 'lodash';

class AmountRange extends React.Component {
  constructor(props){
    super(props)
    this.state={min: props.value.min, max: props.value.max, initialState: true}
  }

  changeMin({target: {name, value}}){
    const {initialState} = this.state;
    if (initialState){
      this.changeState({min: value, max: value})
    }
    else {
      this.changeState({min: value})
    }
  }

  changeMax({target: {name, value}}){
    this.changeState({max: value})
  }

  changeState(state){
    const {min, max} = state;
    this.setState(state, () => {
      this.debouncedChange({min, max})
    })
  }

  debouncedChange = debounce(this.change.bind(this), 250)

  change(state){
    this.props.onChange(state)
  }

  hasError() {
    const {min, max} = this.state;
    return parseFloat(min) > parseFloat(max)
  }

  render() {
    const {min, max, initialState} = this.state;
    return (<><Row className="d-flex">
          <Col className='d-flex'>
            <div className="labeled-box">
              <div className="labeled-box-label">Min</div>
              <Input name='min' onChange={this.changeMin.bind(this)} value={min} type="number" style={{borderRadius: '0px'}}/>
            </div>
            <div className="labeled-box">
              <div className="labeled-box-label ">Max</div>
              <Input
                  className={`${initialState ? 'bg-light': null}`}
                  style={{borderRadius: '0px'}}
                  onClick={() => this.setState({initialState: false})}
                  onChange={this.changeMax.bind(this)} name='max'
                  value={max} type="number"/>
            </div>
          </Col>
        </Row>
          {this.hasError() && <Row>
            <small className="text-danger" style={{position: 'relative', bottom: '16px', left: '65px'}}>MAX cannot be
              less than MIN.</small>
          </Row>}
        </>
    )
  }
}

export default AmountRange;
