import React, {} from "react";
import {Card} from "antd";
import {connect} from "react-redux";
import NotesDisplay from "../../../orders/notesDisplay";

const ShowNotesDisplay = ({order, setChanged}) => (
  <Card>
    <NotesDisplay order={order} onNewNoteSuccess={() => setChanged(true)} />
  </Card>
);

export default connect(({admins}) => ({admins}))(ShowNotesDisplay);
