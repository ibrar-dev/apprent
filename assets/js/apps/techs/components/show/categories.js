import React from 'react';
import {connect} from 'react-redux';
import {DropdownItem, ButtonDropdown, DropdownMenu, Collapse} from 'reactstrap';
import actions from '../../actions';

class Category extends React.Component {
  state = {
    expand: false,
  };

  selectCategory() {
    const {cat, tech} = this.props;
    cat.children.forEach(child => {
      !tech.category_ids.includes(child.id) && tech.category_ids.push(child.id)
    });
    actions.changeTech(tech, tech.category_ids);
  }

  unselectCategory() {
    const {cat, tech} = this.props;
    const childIds = cat.children.map(c => c.id);
    tech.category_ids = tech.category_ids.filter(id => !childIds.includes(id));
    actions.changeTech(tech, tech.category_ids);
  }

  changeCat(id, e) {
    const {tech} = this.props;
    if (e.target.checked) {
      tech.category_ids.push(id)
    } else {
      tech.category_ids.splice(tech.category_ids.indexOf(id), 1);
    }
    actions.changeTech(tech, tech.category_ids);
  }

  expandList() {
    this.setState({...this.state, expand: !this.state.expand});
  }

  render() {
    const {cat, tech} = this.props;
    const {expand} = this.state;
    const catCount = cat.children.reduce((count, c) => tech.category_ids.includes(c.id) ? count + 1 : count, 0);
    return <React.Fragment key={cat.id}>
      <DropdownItem header>
        <a className="d-flex justify-content-between align-items-center"
           onClick={this.expandList.bind(this)}>
          <div>
            <span style={{fontSize: '1.5em'}}>{cat.name} </span>
            <span> [{catCount}]</span>
          </div>
          <i className={`fas fa-chevron-${expand ? 'down' : 'right'}`}
             style={{fontSize: '1em', cursor: 'pointer'}}/>
        </a>
      </DropdownItem>
      <Collapse isOpen={expand}>
        <div className="dropdown-item d-flex justify-content-between">
          <a className="badge badge-light badge-pill position-static"
             onClick={this.selectCategory.bind(this)}>
            Select All
          </a>
          <a className="badge badge-light badge-pill position-static"
             onClick={this.unselectCategory.bind(this)}>
            Unselect All
          </a>
        </div>
        {cat.children && cat.children.map(child => {
          return <label className="dropdown-item mb-0" key={child.id}>
            <input type="checkbox"
                   onChange={this.changeCat.bind(this, child.id)}
                   checked={tech.category_ids.includes(child.id)}/>
            {' '}{child.name}
          </label>;
        })}
      </Collapse>
    </React.Fragment>
  }
}

class Categories extends React.Component {
  state = {};

  render() {
    const {tech, categories} = this.props;
    return categories.map(cat => {
      return <Category key={cat.id} tech={tech} cat={cat} expand={false}/>
    });
  }
}

export default connect(({tech, categories}) => {
  return {tech, categories};
})(Categories);