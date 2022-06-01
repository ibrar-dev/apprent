import React from "react";
import moment from "moment"
import {Row, Col} from "reactstrap"
import {isUser} from "../../../utils";

const Note = ({note, last}) => {
  if (isUser(`${note.admin_id}`)) {
    return (
      <Row className="m-2 d-flex">
        <div
          className="ml-auto col-auto rounded"
          style={{backgroundColor: "rgb(220, 248, 198)", maxWidth: "60%", minWidth: "20%"}}
        >
          <Row>
            <Col><small className="font-weight-bold">You</small></Col>
          </Row>
          <Row>
            <Col>{note.note}</Col>
          </Row>
          <Row>
            <div className="ml-auto col-auto">
              <span className="text-muted" style={{fontSize: "0.7em"}}>
                {moment.utc(note.inserted_at).fromNow()}
              </span>
            </div>
          </Row>
        </div>
      </Row>
    )
  } else {
    return (
      <Row className="m-2 d-flex">
        <div className="mr-auto col-auto rounded bg-light" style={{maxWidth: "60%"}}>
          <Row><Col><small className="font-weight-bold">{note.admin}</small></Col></Row>
          <Row><Col>{note.note}</Col></Row>
          <Row>
            <div className="ml-auto col-auto">
              <span className="text-muted" style={{fontSize: "0.7em"}}>
                {moment.utc(note.inserted_at).fromNow()}
              </span>
            </div>
          </Row>
        </div>
      </Row>
    )
  }
};

export default Note;
