import React from 'react';
import {Provider, connect} from 'react-redux';
import {Row, Col} from 'reactstrap';
import store from '../store';
import Sidebar from './sidebar';
import Property from './property';
import FormBody from './formBody';
import Toolbar from './toolbar';

class MainSection extends React.Component {
  render() {
    const {currentStage, stages} = this.props;
    if(stages.length === 0) return null;
    const stageDiff = stages.length - currentStage - 1;
    return <div>
      <FormBody/>
      {stageDiff > 0 && !window.APPLICATION_JSON && <Toolbar currentStage={currentStage}/>}
    </div>;
  }
}

const Main = connect((s) => {
  const stages = Object.keys(s.application);
  const currentStage = stages.indexOf(s.stage);
  return {currentStage, stages};
})(MainSection);

class ApplicationForm extends React.Component {
  render() {
    return <Provider store={store}>
      <div className="container-fluid">
        <Row>
          <Col xl="3" lg="3">
            <Property />
          </Col>
          <Col xl="2" lg="3">
            <Sidebar />
          </Col>
          <Col xl="7" lg="6">
            <Main />
          </Col>
        </Row>
      </div>
    </Provider>;
  }
}

export default ApplicationForm;
