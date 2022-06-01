import React from "react";
import {connect} from "react-redux";
import actions from "../actions";
import {Row, Col, Button} from "reactstrap";
import AgentCard from "./agentCard";

class AgentsApp extends React.Component {
  componentWillMount() {
    actions.getAgents();
  }

  render() {
    return (
      <div>
        <Row>
          {this.props.agents.map((agent) => {
            return (<AgentCard key={agent.id} {...agent} />)
          })}
        </Row>
        <Row>
          <Col>
            <Button size="lg" color="danger" onClick={actions.addAgent.bind(this, {id: 0, editMode: true})}>
              Add New
            </Button>
          </Col>
        </Row>
      </div>)
  }
}

export default connect((state) => {
  return {agents: state.agents}
})(AgentsApp)