import React from 'react';
import {Col, Card, Badge, CardBody, Collapse, Alert} from 'reactstrap';
import SubCategory from './subCategory';
import actions from '../actions';

class Category extends React.Component {
	state = {
		visible: false,
		newVisible: false,
		newSubCat: '',
		newError: false
	}

	updateShow() {
		var catVisible = this.state.visible;
		this.setState({...this.state, visible: !catVisible})
	}

	updateNew() {
		var newSCVisible = this.state.newVisible;
		this.setState({...this.state, newVisible: !newSCVisible})
	}

	updateNewSubCat(e) {
		this.setState({...this.state, newSubCat: e.target.value});
	}


	saveNewSubCat() {
		var {newSubCat} = this.state;
		var {category} = this.props;
		newSubCat.length > 1 ? actions.saveNewCat(newSubCat, [category.id]).then(this.updateNew.bind(this)) : this.setState({...this.state, newError: true});
	}

	onDismiss() {
		this.setState({...this.state, newError: false})
	}

	render() {
		const {category, filter} = this.props;
		const {visible, newVisible, newSubCat, newError} = this.state;
		return <Col md={6}>
			<Card>
				<a onClick={this.updateShow.bind(this)}  className="card-header">{category.name}  <i className={`fa ${visible ? 'fa-arrow-down' : 'fa-arrow-right'}`}></i> <Badge className="float-right">{category.children.length}</Badge> </a>
				<Collapse isOpen={visible}>
					<CardBody>
						{newError && <Alert color="danger" toggle={this.onDismiss.bind(this)}>The New Category Cannot Be Blank</Alert>}
						<ul className="list-group">
							{category.children.map(sc => sc.name.toLowerCase().includes(filter) ? <SubCategory key={sc.id} subCat={sc} /> : null)}
							{newVisible &&
							<li className="list-group-item">
								<div className="input-group">
									<button className="btn btn-outline-secondary" type="button" onClick={this.saveNewSubCat.bind(this)}>Save</button>
									<input className="form-control" type="text" onChange={this.updateNewSubCat.bind(this)} value={newSubCat}></input>
								</div>
							</li>}
							<a onClick={this.updateNew.bind(this)} className={`list-group-item list-group-item-action list-group-item-${newVisible ? 'danger' : 'success'} text-center`}><i className={`fa ${newVisible ? 'fa-minus' : 'fa-plus'}`}></i></a>
						</ul>
					</CardBody>
				</Collapse>
			</Card>
		</Col>
	}
}

export default Category;
