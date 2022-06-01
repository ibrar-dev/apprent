import React from 'react';
import {Col, Card, Input, Button, CardHeader} from 'reactstrap';
import actions from '../actions';

class NewCategory extends React.Component {
	state = {
		newCat: ''
	}

	updateNewCat(e) {
		this.setState({...this.state, newCat: e.target.value});
	}

	saveNewCat() {
		var name = this.state.newCat;
		actions.saveNewCat(name, []);
	}

	render() {
		const {newCat} = this.state;
		return <Col md={6}>
			<Card outline color="">
				<CardHeader>New Parent Category</CardHeader>
				<div className="card-footer">
					<div className="w-75 d-inline-block pr-1">
						<Input name="name" value={newCat} onChange={this.updateNewCat.bind(this)} />
					</div>
					<div className="w-25 d-inline-block pr-1">
						<Button color="secondary" block onClick={this.saveNewCat.bind(this)}>Save</Button>
					</div>
				</div>
			</Card>
		</Col>
	}
}

export default NewCategory;