import React, {Component} from 'react';
import {Row, Col, Card, CardBody, Label, Button, ButtonGroup, Input} from 'reactstrap';

class BedBugs extends Component {
  change(field, value) {
    if (this.props.lease.locked) return;
    this.props.onChange(field, value);
  }

  changeDisclosure({target: {name, value}}) {
    this.props.onChange(name, value);
  }

  render() {
    const {lease} = this.props;
    return <div>
      <h3>Bugs</h3>
      <Row className="mr-0">
        <Col md={12}>
          <Card>
            <CardBody>
              <div className='form-group'>
                <Label>The applicant</Label>
                <br/>
                <ButtonGroup vertical>
                  <Button onClick={this.change.bind(this, "bug_inspection", 1)} outline color="info"
                          active={lease.bug_inspection === 1}>
                    has inspected the dwelling prior to move-in.
                  </Button>
                  <Button onClick={this.change.bind(this, "bug_inspection", 2)} outline color="info"
                          active={lease.bug_inspection === 2}>
                    will inspect the dwelling within 48 hours after move-in.
                  </Button>
                </ButtonGroup>
              </div>
            </CardBody>
          </Card>
        </Col>
        <Col md={12}>
          <Card>
            <CardBody>
              <div className='form-group'>
                <Label>Applicant</Label>
                <br/>
                <ButtonGroup vertical>
                  <Button onClick={this.change.bind(this, "bug_infestation", 1)} outline color="info"
                          active={lease.bug_infestation === 1}>is not aware of any infestation or presence of bed bugs
                  </Button>
                  <Button onClick={this.change.bind(this, "bug_infestation", 2)} outline color="info"
                          active={lease.bug_infestation === 2}>agrees that if they previously lived anywhere that had a bed
                    bug infestation...
                  </Button>
                </ButtonGroup>
                <p className="mt-3">Disclosure of any previous bed bug infestation which the applicant may have experienced:</p>
                <Input type="textarea" value={lease.bug_disclosure || ''} rows={4} name="bug_disclosure"
                       disabled={lease.locked} onChange={this.changeDisclosure.bind(this)}/>
              </div>
            </CardBody>
          </Card>
        </Col>
      </Row>
    </div>
  }
}

export default BedBugs;