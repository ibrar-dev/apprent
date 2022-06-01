import React, {Component, Fragment} from 'react';
import {connect} from 'react-redux';
import {
  Row, Col, Card, CardTitle, ListGroup, ListGroupItem, Badge, Input, Button, Nav, NavItem, NavLink
} from 'reactstrap';
import actions from '../../actions';
import Material from './material';
import ToolboxComponent from './toolboxComponent';
import Chart from './chart';

class Toolbox extends Component {
  state = {
    search: '',
    activeTab: 'mats'
  };

  _handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      this.searchMaterial();
    }
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
    const {items, searchResults, chart} = this.props;
    const {search, materials, activeTab, selectedType} = this.state;
    const toolboxItems = items.filter(i => i.status === "checked_out");
    return <Row>
      {!chart && <Fragment>
        <Col>
          <Card body>
              <CardTitle>Search For Materials</CardTitle>
              <div className="input-group">
                <Input placeholder="Search for material" onChange={this.updateSearch.bind(this)} value={search} onKeyPress={this._handleKeyPress} />
                <Button outline color="info" onClick={this.searchMaterial.bind(this)}><i className="fas fa-search" /></Button>
              </div>
              {searchResults.categories && searchResults.materials && <Fragment>
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
                      return <Material key={m.id} m={m} tech={this.props.tech} search={search} />
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
                      return <Material key={m.id} m={m} tech={this.props.tech} search={search} />
                    })}
                  </div>}
                </Card>}
              </Fragment>}
          </Card>
        </Col>
        <Col>
          <ToolboxComponent toolboxItems={toolboxItems} />
        </Col>
      </Fragment>}
      {chart && <Col><Chart items={items} /></Col>}
    </Row>
  }
}

export default connect(({searchResults, tech}) => {
  return {searchResults, tech}
})(Toolbox);