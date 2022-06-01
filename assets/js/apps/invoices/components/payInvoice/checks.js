import React, {Component} from 'react';
import {
  Card,
  CardBody,
  Col,
  Row,
  Button,
  FormFeedback,
  FormGroup,
  Label,
  ListGroup,
  ListGroupItem,
  Badge
} from 'reactstrap'
import DatePicker from '../../../../components/datePicker';
import {toCurr, numToLang} from '../../../../utils';
import {ValidatedSelect, validate} from '../../../../components/validationFields';
import moment from 'moment'

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class Check extends Component {

  update(name, value, check){
    let {checks} = this.props;
    const checkIndex = checks.findIndex(c => c.number == check.number)
    checks.splice(checkIndex, 1, {...check, [name]: value})
    return {checks: checks}
  }

  change({target: {name, value}}, check){
    this.props.change(() => this.update(name, value, check))
  }

  render() {
    const {checks, payees, currentCheck, payments} = this.props;
    return <>
      {checks.map(check => {
        return <Card body key={check.number}
                              style={{
                                cursor: "pointer",
                                borderWidth: '2px',
                                borderColor: currentCheck.number === check.number ? 'green' : 'gainsboro'
                              }}
                              onClick={() => this.props.selectCheck(check)}
                              className={`${currentCheck.number === check.number ? "bg-light" : 'hover-glow'} mb-1`}
        >
          <Row>
            <Col className='d-flex justify-content-end align-items-center'>
              <i onClick={(e) => this.props.removeCheck(e, check)}
                 className='fas fa-times text-danger'></i>
            </Col>
          </Row>
          <Row>
            <Col md='8'>
              <div className='labeled-box'>
                <DatePicker name="date" value={check.date} onChange={(e) => this.change(e, check)}/>
                <div className='labeled-box-label'>Date</div>
              </div>
            </Col>
            <Col>
              {check.number}
            </Col>
          </Row>
          <Row className='mt-2'>
            <Col>
              To: <Badge color='info'>{check.payee_id && payees.find(p => p.id == check.payee_id).name}</Badge>
            </Col>
            <Col className='d-flex justify-content-end'>
              <h6 className="text-success">
                {
                  toCurr(sum(Object.values(payments).filter(p => p.check_id === check.number), "amount"))
                }
              </h6>
            </Col>
          </Row>
        </Card>
      })
      }
    </>
  }

}

export default Check;
