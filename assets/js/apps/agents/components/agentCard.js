import React from "react";
import {connect} from "react-redux";
import actions from "../actions";
import {Col, Card, CardBody, CardTitle, CardText, Input} from "reactstrap";

class AgentCard extends React.Component {
  constructor(props) {
    super(props);
    this.state = props;
  }

  componentWillReceiveProps(nextProps) {
    this.setState(nextProps);
  }

  edit(e) {
    e.preventDefault();
    if (this.state.editMode) {
      this.save()
    } else {
      this.setState({...this.state, editMode: !this.state.editMode})
    }
  }

  save() {
    let {editMode, ...agentFields} = this.state;
    actions.updateAgent(agentFields).then((r) => {
      this.setState({...r, editMode: false})
    }).catch((e) => {
    })
  }

  fieldFor(fieldName) {
    if (this.state.editMode) {
      return (<Input value={this.state[fieldName]}
                     placeholder={fieldName}
                     onChange={(r) => {
                       this.setState({...this.state, [fieldName]: r.target.value})
                     } }/>)
    }
    else {
      return this.state[fieldName]
    }
  }

  render() {
    return (
      <Col sm="3">
        <Card>
          <CardBody>
            <CardTitle>
              {this.fieldFor('first_name')}&nbsp;
              {this.fieldFor('last_name')}
            </CardTitle>
            <CardText>
              {this.fieldFor('email')}
            </CardText>
            <CardText>
              <a href="#" className={`btn btn-${this.state.editMode ? 'success' : 'info'}`}
                 onClick={this.edit.bind(this)}>
                { this.state.editMode ? 'Save' : 'Edit Fields' }
              </a>
            </CardText>
          </CardBody>
        </Card>
      </Col>
    )
  }
}

export default connect()(AgentCard)