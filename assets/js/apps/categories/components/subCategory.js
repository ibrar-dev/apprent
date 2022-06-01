import React, { Component } from 'react';
import { Input } from 'reactstrap';
import actions from '../actions';

class SubCategory extends Component {
	state = {
		edit: false,
		name: this.props.subCat.name,
	}

	editName() {
		this.setState({...this.state, edit: !this.state.edit});
	}

	change(e) {
		this.setState({...this.state, name: e.target.value});
	}

	saveName() {
		actions.saveUpdatedCat(this.state.name, this.props.subCat.id);
		this.setState({...this.state, edit: false});
	}

	render() {
		const { edit, name } = this.state;
		const { subCat } = this.props;
		return (
				<li className="list-group-item">
					{!edit &&
						<React.Fragment>
							{subCat.name}
							<a className="float-right" onClick={this.editName.bind(this)}><i className="fas fa-edit text-info"></i></a>
						</React.Fragment>}
					{edit &&
						<div className='d-flex align-items-center'>
							<Input
								className='w-auto mr-1'
								value={name}
								onChange={this.change.bind(this)} />
								<a className="p-1" onClick={this.saveName.bind(this)}><i className="fas fa-save text-success"></i></a>
								<a className="p-1" onClick={this.editName.bind(this)}><i className="fas fa-close text-danger"></i></a>
						</div>}
				</li>
		)
	}
}

export default SubCategory;
