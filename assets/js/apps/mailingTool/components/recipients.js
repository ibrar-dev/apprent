import React, {Component} from 'react';
import {connect} from 'react-redux';
import {
  Card, CardHeader, Collapse, CardBody, Row, Col, ButtonGroup,
  Button, InputGroupAddon, Input, Pagination, PaginationItem,
  DropdownToggle, DropdownItem, DropdownMenu, PaginationLink,
  InputGroup, InputGroupButtonDropdown
} from 'reactstrap';
import actions from '../actions';

const allCurrentPresets = ['all', 'all_current'];
const allFuturePresets = ['all', 'all_future'];

class Recipients extends Component {
  state = {
    preset: '',
    expand: true,
    expandSelected: true,
    actualRecipients: this.props.selectedRecipients,
    filterVal: '',
    page: 1,
    activePresets: [],
    dropdown: false,
    properties_id: []
  }

  static getDerivedStateFromProps(props, state) {
    state.actualRecipients = props.selectedRecipients;
    return state;
  }
  toggleExpand() {
    this.setState({...this.state, expand: !this.state.expand})
  }

  toggleExpandSelected() {
    this.setState({...this.state, expandSelected: !this.state.expandSelected})
  }

  setPreset(value) {
    this.setState({...this.state, preset: value}, () => actions.fetchRecipients(value))
  }

  setPage(value) {
    this.setState({...this.state, page: value})
  }

  setProperty(property_id, type) {
    const {activePresets, properties_id} = this.state;
    const {selectedRecipients} = this.props;
    if (activePresets.indexOf(`${type}-${property_id}`) === -1) {
      activePresets.push(`${type}-${property_id}`);
      properties_id.push(property_id);
      actions.setPropertyIds(properties_id)
      this.setState({...this.state, activePresets: activePresets}, () => actions.fetchPropertyRecipients(property_id, type))
    } else {
      activePresets.splice(activePresets.indexOf(`${type}-${property_id}`), 1);
      const newList = selectedRecipients.filter(r => activePresets.includes(`${r.type}-${r.property_id}`));
      this.setState({activePresets: activePresets}, () => actions.setSelectedRecipients(newList));
      properties_id.splice( properties_id.indexOf((property_id), 1))
      actions.setPropertyIds(properties_id)
    }
  }

  updateFilter(e) {
    this.setState({...this.state, filterVal: e.target.value, page: 1 })
  }

  toggleResident(resident) {
    const {actualRecipients} = this.state;
    const recipients = this.props.selectedRecipients;
    let res = recipients.filter(r => r.id === resident.id)[0];
    res.checked = !res.checked;
    actions.setSelectedRecipients(recipients);
    this.setState({...this.state, actualRecipients: actualRecipients})
  }

  filteredResidents(residents) {
    const {filterVal, page} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return residents.filter(r => (filter.test(r.name) || filter.test(r.email) || filter.test(parseInt(r.unit))))
  }

  residentsToDisplay(residents) {
    const {page} = this.state;
    if (residents.length > 75) {
      return residents.slice((page * 75), ((page * 75) + 75))
    }
    else{
      return residents
    }
  }

  clearSelection() {
    this.setState({...this.state, preset: '', activePresets: []}, () => actions.clearSelection())
  }

  toggleDropdown() {
    this.setState({...this.state, dropdown: !this.state.dropdown});
  }
  multiSelect(type) {
    actions.setAllRecipients(type);
  }
  render() {
    const {selectedRecipients, properties,  templates} = this.props;
    const {expand, preset, expandSelected, filterVal, page, actualRecipients, activePresets, dropdown, properties_id} = this.state;
    const pagesToDisplay = Math.floor(this.filteredResidents(selectedRecipients).length / 75);
    const firstPage = 1
    return <Card>
      <CardHeader style={{cursor: 'pointer'}} onClick={this.toggleExpand.bind(this)} className="d-flex justify-content-between"><span>Recipients</span><i className={`fas fa-caret-${expand ? 'up' : 'down'}`} /></CardHeader>
      <Collapse isOpen={expand}>
        <CardBody>
          <Row>
            <Col md={5} style={{maxHeight: 350, overflowY: "scroll"}}>
              <Row>
                <Col className='d-flex flex-column'>
                  <Col>Presets - All</Col>
                  <Col>
                    <ButtonGroup>
                      <Button outline color="info" active={preset === 'all'} onClick={this.setPreset.bind(this, 'all')}>Everyone (Ever)</Button>
                      <Button outline color="info" active={preset === 'all_current'} onClick={this.setPreset.bind(this, 'all_current')}>Current Residents</Button>
                      <Button outline color="info" active={preset === 'all_future'} onClick={this.setPreset.bind(this, 'all_future')}>Future Residents</Button>
                      <Button outline color="info" active={preset === 'all_past'} onClick={this.setPreset.bind(this, 'all_past')}>Past Residents</Button>
                      {selectedRecipients.length >= 1 && <Button outline color="warning" onClick={this.clearSelection.bind(this)}>Clear</Button>}
                    </ButtonGroup>
                  </Col>
                </Col>
              </Row>
              {properties.length && <Row>
                <Col className="d-flex flex-column mt-1">
                  <Col>Properties</Col>
                  {properties.map(p => {
                    return <Col key={p.id} className="mt-1">
                        <ButtonGroup>
                          <Button disabled outline={!(preset === `current-${p.id}` || preset === `future-${p.id}`)} color='info'>{p.name}</Button>
                          <Button disabled={allCurrentPresets.includes(preset)} active={activePresets.includes(`current-${p.id}`)} outline color="info" onClick={this.setProperty.bind(this, p.id, `current`)}>Current Residents</Button>
                          <Button disabled={allFuturePresets.includes(preset)} active={activePresets.includes(`future-${p.id}`)} outline color="info" onClick={this.setProperty.bind(this, p.id, `future`)}>Future Residents</Button>
                        </ButtonGroup>
                    </Col>
                  })}
                </Col>
              </Row>}
            </Col>
            <Col md={7}>
              <Card>
                <CardHeader className="d-flex justify-content-between">
                  <span>Selected Recipients</span>
                  {selectedRecipients.length >= 1 && <InputGroup>
                    <InputGroupButtonDropdown addonType="prepend" isOpen={dropdown} toggle={this.toggleDropdown.bind(this)}>
                      <Button onClick={this.toggleDropdown.bind(this)} outline size="sm">Options</Button>
                      <DropdownToggle onClick={e => e.stopPropagation()} split outline />
                      <DropdownMenu>
                        <DropdownItem onClick={this.multiSelect.bind(this, true)}>Select All</DropdownItem>
                        <DropdownItem onClick={this.multiSelect.bind(this, false)}>Un-Select All</DropdownItem>
                      </DropdownMenu>
                    </InputGroupButtonDropdown>
                    <Input onClick={e => e.stopPropagation()} value={filterVal} onChange={this.updateFilter.bind(this)} placeholder="Search" />
                  </InputGroup>}
                  <span className="badge">{selectedRecipients.filter(r => r.checked).length}</span>
                </CardHeader>
                {selectedRecipients.length >= 1 && <Collapse isOpen={expandSelected}>
                  <CardBody style={{maxHeight: 350, overflowY: "scroll"}}>
                    <Row>
                      {this.residentsToDisplay(this.filteredResidents(actualRecipients)).map(r => {
                        return <Col sm={6} key={r.id}>
                          <div className="input-group" onClick={this.toggleResident.bind(this, r)}>
                            <InputGroupAddon addonType="prepend">
                              <div className="input-group-text">
                                <Input addon type="checkbox" onChange={this.toggleResident.bind(this, r)} checked={r.checked} />
                              </div>
                            </InputGroupAddon>
                            <Input style={{resize: 'none'}} rows="2" disabled type="textarea" value={`${r.name}\n${r.unit || ""} - ${r.property}`} />
                            {/*<Input disabled value={r.name} />*/}
                            {/*<Input disabled value={`${r.unit || ""} - ${r.property}`} />*/}
                          </div>
                        </Col>
                      })}
                    </Row>
                    {pagesToDisplay > 1 && this.state.filterVal.length < 1 &&  <Row className="mt-1">
                      <Col>
                        <Pagination>
                          <PaginationItem>
                            <PaginationLink disabled={page <= 1} onClick={this.setPage.bind(this, page - 1)}>
                              <i className="fas fa-caret-left" />
                            </PaginationLink>
                          </PaginationItem>
                            {page != 1  &&
                            <PaginationItem  onClick={this.setPage.bind(this, firstPage)}>
                              <PaginationLink>{firstPage}</PaginationLink>
                            </PaginationItem>}
                          <PaginationItem active>
                          <PaginationLink>{page}</PaginationLink>
                          </PaginationItem>
                          {page + 1 < pagesToDisplay && <PaginationItem onClick={this.setPage.bind(this, page + 1)}>
                            <PaginationLink>{page + 1}</PaginationLink>
                          </PaginationItem>}
                          {page + 2 < pagesToDisplay && <PaginationItem onClick={this.setPage.bind(this, page + 2)}>
                            <PaginationLink>{page + 2}</PaginationLink>
                          </PaginationItem>}
                          {page + 3 < pagesToDisplay && <PaginationItem onClick={this.setPage.bind(this, page + 3)}>
                            <PaginationLink>{page + 3}</PaginationLink>
                          </PaginationItem>}
                          {page + 5 < pagesToDisplay && <PaginationItem disabled>
                            <PaginationLink>...</PaginationLink>
                          </PaginationItem>}
                          {page !== pagesToDisplay && <PaginationItem onClick={this.setPage.bind(this, pagesToDisplay)}>
                            <PaginationLink>{pagesToDisplay}</PaginationLink>
                          </PaginationItem>}
                          <PaginationItem>
                            <PaginationLink disabled={page === pagesToDisplay}  onClick={this.setPage.bind(this, page + 1)}>
                              <i className="fas fa-caret-right" />
                            </PaginationLink>
                          </PaginationItem>
                        </Pagination>
                      </Col>
                    </Row>}
                  </CardBody>
                </Collapse>}
              </Card>
            </Col>
          </Row>
        </CardBody>
      </Collapse>
    </Card>
  }
}

export default connect(({selectedRecipients, residents, properties,  activePresets, templates}) => {
  return {selectedRecipients, residents, properties, activePresets, templates }
})(Recipients)