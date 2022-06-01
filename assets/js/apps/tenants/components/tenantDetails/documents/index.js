import React from 'react';
import {connect} from 'react-redux';
import {ButtonGroup, Card, CardHeader, CardBody, Button} from 'reactstrap';
import Create from './create';
import Upload from './upload';
import View from './view';
import actions from '../../../actions';

class Documents extends React.Component {
  state = {visible: true, activeButton: 'view'};

  static getDerivedStateFromProps(props, state) {
    const template = state.template ? props.propertyTemplates.find(x => x.id === state.template.id) : null;
    return {template};
  };

  componentDidMount() {
    actions.fetchTemplates(this.props.tenant.unit.property_id)
  };

  setActive(active) {
    this.setState({activeButton: active});
  }

  render() {
    const {activeButton} = this.state;
    const {tenant} = this.props;
    return <Card className="ml-3">
      <CardHeader className="d-flex align-items-center py-2">
        <div>Documents</div>
        <ButtonGroup className="bg-white ml-4">
          {tenant.application_id &&
          <a className="btn btn-sm btn-outline-success" href={`/applications/${tenant.application_id}`}>
            View Application
          </a>}
          <Button color="success" active={activeButton === 'view'} outline size="sm"
                  onClick={this.setActive.bind(this, "view")}> View </Button>
          <Button color="success" active={activeButton === 'upload'} outline size="sm"
                  onClick={this.setActive.bind(this, "upload")}>Upload</Button>
          <Button color="success" active={activeButton === 'create'} outline size="sm"
                  onClick={this.setActive.bind(this, "create")}>Create</Button>
        </ButtonGroup>
      </CardHeader>
      <CardBody>
        {activeButton === 'view' && <View tenant={tenant}/>}
        {activeButton === 'upload' && <Upload tenant={tenant}/>}
        {activeButton === 'create' && <Create tenant={tenant}/>}
      </CardBody>
    </Card>
  }
}

export default connect(({tenant, propertyTemplates}) => {
  return {tenant, propertyTemplates};
})(Documents);
