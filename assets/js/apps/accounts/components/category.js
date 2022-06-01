import React, {Component} from 'react';
import {Input, Button} from 'reactstrap';
import confirmation from '../../../components/confirmationModal';
import actions from '../actions';
import FancyCheck from '../../../components/fancyCheck';

class Category extends Component {
  state = {
    edit: false,
    category: this.props.category
  };

  toggleEdit() {
    const {editMode} = this.state;
    if (editMode) this.save();
    this.setState({editMode: !editMode});
  }

  change({target: {name, value}}) {
    const {category} = this.state;
    category[name] = value;
    this.setState({category})
  }

  changeFlag({target: {name, checked}}) {
    const {category} = this.state;
    category[name] = checked;
    this.setState({category})
  }

  save() {
    actions.updateCategory(this.state.category);
    this.setState({editMode: false});
  }

  deleteCategory() {
    const {category} = this.state;
    confirmation('Please confirm you would like to delete this category').then(() => {
      actions.deleteCategory(category.id)
    })
  }

  render() {
    const {editMode, category} = this.state;
    if (editMode) return <tr>
      <td className="align-middle text-center">
        <a onClick={this.toggleEdit.bind(this)}>
          <i className="fas fa-save fa-lg text-success"/>
        </a>
      </td>
      <td colSpan={3}>
        <div className="d-flex">
          <div className="labeled-box">
            <Input name="num" value={category.num || ''} onChange={this.change.bind(this)}/>
            <div className="labeled-box-label">Number</div>
          </div>
          <div className="labeled-box ml-3">
            <Input name="max" type="number" value={category.max || ''} onChange={this.change.bind(this)}/>
            <div className="labeled-box-label">Total Account</div>
          </div>
          <div className="labeled-box ml-3" style={{minWidth: 300}}>
            <Input name="name" value={category.name || ''} onChange={this.change.bind(this)}/>
            <div className="labeled-box-label">Name</div>
          </div>
          <div className="ml-3">
            <Button color="danger" onClick={this.deleteCategory.bind(this)}>
              Delete Category
            </Button>
          </div>
        </div>
      </td>
      <td className="align-middle text-center">
        <FancyCheck inline
                    name="total_only"
                    checked={category.total_only}
                    value={category.total_only}
                    onChange={this.changeFlag.bind(this)}/>
      </td>
      <td className="align-middle text-center">
        <FancyCheck inline
                    name="in_approvals"
                    checked={category.in_approvals}
                    value={category.in_approvals}
                    onChange={this.changeFlag.bind(this)}/>
      </td>
      <td />
      <td className="align-middle text-center">
        <FancyCheck inline
                    name="is_balance"
                    checked={category.is_balance}
                    value={category.is_balance}
                    onChange={this.changeFlag.bind(this)}/>
      </td>
      <td colSpan={2}/>
    </tr>;
    return <tr>
      <td>
        {category.type === "category" && <a onClick={this.toggleEdit.bind(this)}>
          <i className="fas fa-edit fa-lg"/>
        </a>}
      </td>
      <td>
        <b>{category.num}</b>
      </td>
      <td colSpan={2}>
        <b>
          {category.name}{" "}
          {/*<span className="badge badge-pill badge-light">{!category.header ? 'Category' : 'Total'}</span>*/}
        </b>
      </td>
      <td/>
      <td className="align-middle text-center">
        <i className={`fas fa-${category.total_only ? 'check-square text-success' : 'window-close text-danger'}`}/>
      </td>
      <td className="align-middle text-center">
        <i className={`fas fa-${category.in_approvals ? 'check-square text-success' : 'window-close text-danger'}`}/>
      </td>
      <td />
      <td className="align-middle text-center">
        <i className={`fas fa-${category.is_balance ? 'check-square text-success' : 'window-close text-danger'}`}/>
      </td>
      <td colSpan={2}/>
    </tr>
  }
}

export default Category;