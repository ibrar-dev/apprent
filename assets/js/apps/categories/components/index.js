import React, {Component} from 'react';
import {connect} from 'react-redux';
import Category from './category';
import NewCategory from './newCategory';
import FilterCategories from './filterCategories';

class CategoriesApp extends Component {
	state = {
		filter: '',
		showFlash: false
	}

	updateFilter(e) {
		this.setState({...this.state, filter: e.target.value.toLowerCase()});
	}

	updateShowFlash() {
		this.setState({...this.state, showFlash: !this.showFlash})
	}

	render() {
		const {categories} = this.props;
		const {filter, showFlash} = this.state;
		return <div className="row">
			<NewCategory />
			<FilterCategories change={this.updateFilter.bind(this)} value={filter} />
			{categories.map(cat => cat.name.toLowerCase().includes(filter) ? <Category category={cat} key={cat.id} filter={filter} /> : null)}
		</div>
	}
}

export default connect(({categories}) => {
	return {categories};
})(CategoriesApp)