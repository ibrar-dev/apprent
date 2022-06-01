import React from 'react';
import {Col, Card, Input, Button, CardHeader, CardFooter} from 'reactstrap';

const FilterCategories = (props) => (

		<Col md={6}>
			<Card outline color="">
				<CardHeader>
					Search for a Category
				</CardHeader>
				<CardFooter>
					<div className="w-75 d-inline-block pr-1">
						<Input name="name" value={props.value} onChange={props.change.bind(this)} />
					</div>
					<div className="w-25 d-inline-block pr-1">
						<Button color="secondary" block><i className="fas fa-search"></i></Button>
					</div>
				</CardFooter>
			</Card>
		</Col>
)

export default FilterCategories;