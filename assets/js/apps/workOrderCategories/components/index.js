import React from 'react';
import {connect} from 'react-redux';
import {Row, Col} from 'reactstrap';
import Category from './parent';

class Categories extends React.Component {
  render() {
    const {categories} = this.props;
    return <Row>
      {categories.map(c => <Col sm={4} key={c.id}>
        <Category category={c}/>
      </Col>)}
    </Row>;
  }
}

export default connect(({categories}) => {
  return {categories};
})(Categories);