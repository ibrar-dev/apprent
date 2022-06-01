import React, {Component} from 'react';
import moment from 'moment';
import {Collapse, Card, CardHeader} from 'reactstrap';

class SentEmails extends Component {
  state = {};

  open(emailId) {
    this.setState({openId: emailId === this.state.openId ? null : emailId});
  }

  render() {
    const {emails} = this.props;
    const {openId} = this.state;
    return <div>
      <h4>All Emails</h4>
      <Card className="m-0">
        {emails.map(e => {
          return <React.Fragment key={e.id}>
            <CardHeader className="clickable d-flex justify-content-between align-items-center"
                        onClick={this.open.bind(this, e.id)}>
              <div>{moment(e.inserted_at).format('MM/DD/YYYY')} - {e.subject}</div>
              <div className="d-flex">
                {e.attachments.map((a, i) => {
                  return <a href={a} target="_target"
                            className="btn btn-outline-info btn-sm ml-2"
                            key={i}>Attachment #{i + 1}</a>
                })}
              </div>
            </CardHeader>
            <Collapse isOpen={openId === e.id}>
              <iframe className="border-0 w-100"
                      style={{height: 800}}
                      src={e.body}/>
            </Collapse>
          </React.Fragment>
        })}
      </Card>
    </div>
  }
}

export default SentEmails;