import React, {Component} from 'react';
import {connect} from 'react-redux';
import {titleize} from '../../../utils';
import {Button, Collapse, Input, ListGroup, ListGroupItem, ListGroupItemHeading, ListGroupItemText, Label, Col, Nav, NavItem, NavLink, Badge, Card} from 'reactstrap';
import actions from '../actions';
import canEdit from '../../../components/canEdit';
import Material from './material';

class Materials extends Component {
  state = {
    attach: false,
    activeTab: 'mats',
    search: ''
  }

  reduceCost() {
    const {assignments} = this.props;
    let total = 0;
    assignments.filter(as => as.materials.length >= 1).forEach(a => {
      total = total + (a.materials.reduce((sum, m) => sum + m.cost, 0))
    });
    return parseFloat(total).toFixed(2);
  }

  _handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      this.searchMaterial();
    }
  }

  toggleAttach() {
    this.setState({...this.state, attach: !this.state.attach});
  }

  updateSearch({target: {value}}) {
    this.setState({...this.state, search: value});
  }

  searchMaterial() {
    this.setState({...this.state, materials: null});
    actions.searchForMaterials(this.state.search);
  }

  selectType(type) {
    this.setState({...this.state, selectedType: type.id, materials: type.materials})
  }

  changeTab(type) {
    this.setState({...this.state, activeTab: type});
  }

  render() {
    const {assignments, searchResults} = this.props;
    const {attach, search, selectedType, activeTab, materials} = this.state;
    return <div>
      <table className="table table-bordered">
        <tbody>
        {assignments.map(a => {
          return <React.Fragment key={a.id}>
            <tr className="table-active">
              <td>{a.tech}</td>
              <td>{titleize(a.status)}</td>
            </tr>
            {a.materials.map(m => {
            return <tr key={m.toolbox_item_id}>
              <td>{m.name}</td>
              <td>${m.cost}</td>
            </tr>
          })}
          </React.Fragment>
        })}
          <tr>
            <td className="d-flex justify-content-between">
              <div>
                {canEdit(["Super Admin", "Regional", "Tech"]) && <Button active={attach} outline color="success" onClick={this.toggleAttach.bind(this)} >Add</Button>}
              </div>
              <b>Total Cost:</b>
            </td>
            <td>
              <b>${this.reduceCost()}</b>
            </td>
          </tr>
        </tbody>
      </table>
      <Collapse isOpen={attach}>
        <div className="form-group">
          <Label>Find Material</Label>
          <div className="input-group">
            <Input placeholder="Search for material" onChange={this.updateSearch.bind(this)} value={search} onKeyPress={this._handleKeyPress} />
            <Button outline color="info" onClick={this.searchMaterial.bind(this)}><i className="fas fa-search" /></Button>
          </div>
        </div>
        {searchResults.categories && searchResults.materials && <React.Fragment>
          <Nav pills>
            <NavItem>
              <NavLink active={activeTab === 'mats'} onClick={this.changeTab.bind(this, 'mats')}>
                <i className="fas fa-comments"/>{' '}Materials <Badge>{searchResults.materials.length}</Badge>
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink active={activeTab === 'cats'} onClick={this.changeTab.bind(this, 'cats')}>
                <i className="fas fa-comments"/>{' '}Categories <Badge>{searchResults.categories.length}</Badge>
              </NavLink>
            </NavItem>
          </Nav>
          {searchResults.materials.length >= 1 && activeTab === "mats" && <Card>
            <ListGroup>
              {searchResults.materials.map(m => {
                return <Material m={m} key={m.id} a={assignments[0]} s={search} />
              })}
            </ListGroup>
          </Card>}
          {searchResults.categories.length >= 1 && activeTab === "cats" && <Card>
            <div className="card-header">
              <ListGroup>
                {searchResults.categories.map(t => {
                  return <ListGroupItem active={selectedType === t.id} key={t.id} onClick={this.selectType.bind(this, t)}>
                    {t.name}
                  </ListGroupItem>
                })}
              </ListGroup>
            </div>
            {materials && materials.length >= 1 && <div className="">
              {materials.map(m => {
                return <Material m={m} key={m.id} a={assignments[0]} s={search} />
              })}
            </div>}
          </Card>}
        </React.Fragment>}
      </Collapse>
    </div>
  }
}

export default connect(({searchResults}) => {
  return {searchResults}
})(Materials);
