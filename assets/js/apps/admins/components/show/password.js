import React, {useState} from "react";
import {connect} from "react-redux";
import {
 Button, Form, FormGroup, Label, Input, FormFeedback, FormText, Row, Col, CustomInput
} from "reactstrap";
import { Switch } from 'antd';
import actions from "../../actions";

const Password = ({activeAdmin: {id, reset_pw, active}}) => {
  const [password, setPassword] = useState("");
  const [pending, setPending] = useState(false);
  const [updated, setUpdated] = useState(false);

  const resetPassword = () => {
    setPending(true);
    actions.updateAdmin({id, password});
    setPending(false);
    setUpdated(true);
  };

  const toggleCanResetPassword = (checked) => {
    actions.updateAdmin({id, reset_pw: checked});
  };

  const toggleAdminActive = (checked) => {
    actions.updateAdmin({id, active: checked, bounce: !checked})
  }

  return (
    <Row>
      <Col md={4}>
        <Form>
          <FormGroup inline className="mb-2 mr-sm-2 mb-sm-0">
            <Label for="examplePassword" className="mr-sm-2">Password Reset</Label>
            <Input
              invalid={!!password && password.length < 8}
              type="text"
              name="password"
              id="examplePassword"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <FormFeedback>
              Password must be at least 8 characters
            </FormFeedback>
            {pending && <FormText>Submitting...</FormText>}
            {updated && <FormText color="success">Update Successful!</FormText>}
          </FormGroup>
          <div className="mt-2">
            <Button
              className="mr-1"
              outline
              onClick={() => setPassword("")}
              disabled={pending}
            >
              Clear
            </Button>
            <Button
              disabled={pending || password.length < 8}
              onClick={() => resetPassword()}
            >
              Submit
            </Button>
          </div>
        </Form>
      </Col>
      <Col md={4}>
        <FormGroup inline className="mb-2 mr-sm-2 mb-sm-0">
          <Label for="examplePassword" className="mr-sm-2">Password Reset</Label>
          <Switch
            className="mx-10"
            onChange={toggleCanResetPassword}
            checked={reset_pw}
          />
        </FormGroup>
      </Col>
      <Col md={4}>
        <FormGroup inline className="mb-2 mr-sm-2 mb-sm-0">
          <Label for="examplePassword" className="mr-sm-2">Activate Admin</Label>
          <Switch
            className="mx-10"
            onChange={toggleAdminActive}
            checked={active}
          />
        </FormGroup>
      </Col>
    </Row>
  );
};

export default connect(({activeAdmin}) => ({activeAdmin}))(Password);