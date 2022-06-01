import React from 'react';
import {Card, CardBody, Button, InputGroupAddon, InputGroup, Input} from "reactstrap";
import Transfer from './transfer';
import Header from './parentHeader';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class Parent extends React.Component {
  state = {newChild: null, newName: this.props.category.name};

  moveTo(child) {
    this.setState({transferModal: child});
  }

  deleteCategory(id) {
    confirmation('Delete this category entirely?').then(() => {
      actions.deleteCategory(id);
    })
  }

  newChild() {
    this.setState({newChild: ''});
  }

  saveChild() {
    actions.createChild(this.props.category.id, this.state.newChild).then(() => {
      this.setState({newChild: null});
    })
  }

  changeNewChildName({target: {value}}) {
    this.setState({newChild: value});
  }

  toggleVisibility(id, visible) {
    actions.toggleVisibility(id, {visible: visible});
  }

  toggleThirdParty(id, third_party) {
    actions.toggleVisibility(id, {third_party: third_party})
  }

  render() {
    const {category} = this.props;
    const {transferModal, newChild} = this.state;
    return <React.Fragment>
      <Card>
        <Header category={category} newChild={this.newChild.bind(this)} />
        <CardBody className="overflow-scroll" style={{height: 250}}>
          <ul className="list-group">
            {newChild !== null && <InputGroup className="bordered mb-3">
              <Input value={newChild} className="h-auto" onChange={this.changeNewChildName.bind(this)} />
              <InputGroupAddon addonType="append">
                <Button color="dark" outline onClick={this.saveChild.bind(this)}>
                  <i className={`fas fa-${newChild.length > 0 ? 'save' : 'times'}`}/>
                </Button>
              </InputGroupAddon>
            </InputGroup>}
            {category.children.map(child => {
              return <li className="list-group-item d-flex align-items-center justify-content-between" key={child.id}>
                <div className='d-flex justify-content-start'>
                  <span style={{cursor: 'pointer'}} onClick={this.toggleVisibility.bind(this, child.id, !child.visible)}><i className={`fas fa-${child.visible ? 'eye' : 'eye-slash'} mr-1`} /></span>
                  <span style={{cursor: 'pointer'}} onClick={this.toggleThirdParty.bind(this, child.id, !child.third_party)}><i className={`fas fa-${child.third_party ? 'cogs' : 'cog'} mr-1`} /></span>
                  <div>{child.name}</div>
                </div>
                {child.count > 0 && <div className="badge badge-pill badge-danger"
                                         onClick={this.moveTo.bind(this, child)}
                                         style={{lineHeight: '1.3em', cursor: 'pointer'}}>
                  {child.count}
                </div>}
                {child.count === 0 && <a onClick={this.deleteCategory.bind(this, child.id)}>
                  <i className="fas fa-times text-danger"/>
                </a>}
              </li>;
            })}
          </ul>
        </CardBody>
      </Card>
      {transferModal && <Transfer fromCategory={transferModal} toggle={this.moveTo.bind(this, null)}/>}
    </React.Fragment>
  }
}

export default Parent;