import React from 'react';
import {Popover, PopoverBody, PopoverHeader, Button, Input, Row, Col, Label, FormGroup} from 'reactstrap';
import AmountRange from '../../../components/amountRange'
import moment from 'moment'

class Filters extends React.Component {
  state = {filters: {}};

  toggle() {
    this.setState({open: !this.state.open});
  }

  getState(values){
    const {filters} = this.state;
    Object.keys(values).map(key => {
      const value = values[key]
      if (value) {
        filters[key] = value;
      } else {
        delete filters[key];
      }
    })
    return {filters: filters}
  }

  changeState(state){
    this.setState(state)
    const {filters} = this.props;
    this.props.onChange(state.filters);
  }

  changeRange({min, max}){
    const state = this.getState({min, max})
    this.changeState(state)
  }



  render() {
    const {open, filters} = this.state;
    const numFilters = Object.keys(filters).length - 1;
    return <div>
      <Button color='light' style={{borderColor: 'lightgrey'}}
              onClick={this.toggle.bind(this)} id="advanced-filters">
        {numFilters > 0 ? `${numFilters} Active Filters` : 'Filters'} <i className="fas fa-filter"/>
      </Button>
      <Popover placement="bottom" isOpen={open} target="advanced-filters" className="popover-max"
               toggle={this.toggle.bind(this)}>
        <PopoverHeader>Filters</PopoverHeader>
        <PopoverBody>
          <Row>
            <Col>
              <AmountRange onChange={this.changeRange.bind(this)}
                           value={{min: filters.min, max: filters.max}}/>
            </Col>
          </Row>
          <Row>
            {
              this.props.filters.type &&

              <Col>
                <FormGroup>
                  <Label>{this.props.filters.type} ID</Label>
                  <Input value={this.props.filters.search} name='search' onChange={this.props.onChange}/>
                </FormGroup>
              </Col>
            }
          </Row>
        </PopoverBody>
      </Popover>
    </div>;
  }
}

export default Filters;
