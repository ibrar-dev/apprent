import store from "../categories/store";
import axios from 'axios';;

let generators = {
	setCategories(categories) {
		store.dispatch({
			type: 'SET_CATEGORIES',
			categories
		})
	},
};

let actions = {
	fetchCategories: () => {
		const promise = axios.get('/api/categories');
		promise.then(r => generators.setCategories(r.data));
		return promise;
	},
	saveNewCat: (name, path) => {
		const body = {category: {name, path}};
		const promise = axios.post('/api/categories', body);
		promise.then(actions.fetchCategories);
		return promise;
	},
	saveUpdatedCat: (name, id) => {
		const body = {category: {name}};
		const promise = axios.patch('/api/categories/' + id, body);
		promise.then(actions.fetchCategories);
		return promise;
	},
	deleteCategory(id) {
		const promise = axios.delete('/api/categories/' + id);
		promise.then(actions.fetchCategories);
		return promise;
	},
};

export default actions;
