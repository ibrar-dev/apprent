import React from 'react';
import {Collapse, Card, CardHeader, Badge, ListGroup} from 'reactstrap';
import Document from './document';

class Category extends React.Component {
  state = {};

  toggle() {
    this.setState({open: !this.state.open})
  }

  render() {
    const {category} = this.props;
    const {open} = this.state;
    return <Card>
      <CardHeader onClick={this.toggle.bind(this)} className="clickable d-flex justify-content-between">
        <div>
          <i className={`fas fa-folder${open ? '-open' : ''}`}/> {category.name}
        </div>
        <div>
          <Badge color="danger" className="fa-1x rounded-circle">{category.documents.length}</Badge>
        </div>
      </CardHeader>
      <Collapse isOpen={open}>
        <ListGroup>
          {category.documents.map(d => <Document key={d.id} document={d}/>)}
        </ListGroup>
      </Collapse>
    </Card>;
  }
}

export default Category;