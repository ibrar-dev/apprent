import React from 'react';
import {CardHeader, Input, InputGroup, InputGroupAddon, Button, ButtonGroup} from 'reactstrap';
import confirmation from "../../../components/confirmationModal";
import actions from "../actions";

class ParentHeader extends React.Component {
  state = {newName: this.props.category.name};

  toggleEdit() {
    this.setState({edit: !this.state.edit});
  }

  changeParentName({target: {value}}) {
    this.setState({newName: value});
  }

  deleteCategory() {
    const {category} = this.props;
    if (category.children.length > 0) {
      confirmation('Cannot delete a category with sub-categories. Remove all child categories and then delete the parent.', {
        noCancel: true,
        header: 'Action Invalid'
      });
      return;
    }
    confirmation('Delete this category entirely?').then(() => {
      actions.deleteCategory(category.id);
    })
  }

  update() {
    actions.updateCategory(this.props.category.id, this.state.newName).then(() => {
      this.setState({edit: false});
    })
  }

  render() {
    const {category, newChild} = this.props;
    const {edit, newName} = this.state;
    return <CardHeader className="d-flex justify-content-between align-items-center">
      {edit && <InputGroup className="bordered">
        <Input value={newName} className="h-auto" onChange={this.changeParentName.bind(this)} />
        <InputGroupAddon addonType="append">
          <Button color="dark" outline onClick={this.update.bind(this)}>
            <i className="fas fa-save"/>
          </Button>
        </InputGroupAddon>
      </InputGroup>}
      {!edit && <React.Fragment>
        <div>{category.name}</div>
        <ButtonGroup className="bordered">
          <Button color="light" size="sm" onClick={this.deleteCategory.bind(this)}>
            <i className="fas fa-times pt-1" style={{fontSize: '115%'}}/>
          </Button>
          <Button color="light" size="sm" onClick={this.toggleEdit.bind(this)}>
            <i className="fas fa-edit"/>
          </Button>
          <Button color="light" size="sm" onClick={newChild}>
            <i className="fas fa-folder-plus pt-1" style={{fontSize: '115%'}}/>
          </Button>
        </ButtonGroup>
      </React.Fragment>}
    </CardHeader>;
  }
}

export default ParentHeader;