import React, {useState} from 'react';
import {Popconfirm, Input, Space} from "antd";
import moment from 'moment';
import {PlusCircleTwoTone, CloseSquareTwoTone, CloseCircleTwoTone, WarningTwoTone} from "@ant-design/icons";
import actions from "../../../../actions";

function confirmAssign(tech, orderId, setFinished) {
  actions.assignWorkOrders([orderId], tech.id)
  return setFinished("finished");
}

function confirmRevoke(id, setFinished) {
  actions.revokeAssignment(id);
  return setFinished("finished");
}

function confirmCallback(id, note, setFinished) {
  actions.callbackOrder({id: id}, note);
  return setFinished("finished");
}

const UnassignedExtra = ({tech, order, setFinished}) => {
  return <Popconfirm title={`Assign this order to ${tech.name}`} onConfirm={() => confirmAssign(tech, order.id, setFinished)}>
    <PlusCircleTwoTone style={{fontSize: 28}} twoToneColor={"#28a745"}/>
  </Popconfirm>
}

function getMessageAssigned(activeTech, assignment, tech) {
  if (activeTech) return <span>Revoke this order from <b>{assignment.tech}</b>?</span>
  return <span>Revoke this order from <b>{assignment.tech}</b> and assign it to <b>{tech.name}</b>?</span>
}

const AssignedExtra = ({tech, order, setFinished}) => {
  const a = order.assignments[0];
  const activeTech = tech.id === a.tech_id;
  return <Popconfirm title={getMessageAssigned(activeTech, a, tech)}
                      onConfirm={() => activeTech ? confirmRevoke(a.id, setFinished) : confirmAssign(tech, order.id, setFinished)}
                      >
    {activeTech && <CloseCircleTwoTone style={{fontSize: 28}} twoToneColor={"#d9534f"} />}
    {!activeTech && <span>
        <PlusCircleTwoTone style={{fontSize: 24}} twoToneColor={"#28a745"}/>
      </span>}
  </Popconfirm>
}

function callBackNote(note, setNote) {
  return <Space direction="vertical" size="sm">
    <span>Mark this order as a callback.</span>
    <span>Please enter a reason below.</span>
    <Input placeholder="Reason" value={note} onChange={e => setNote(e.target.value)} />
  </Space>
}

// Return true if assignment completion date is 30 days or less in the past.
function canCallback(order) {
  if (!order.assignments) return false;
  const a = order.assignments[0];
  const thirtyDaysAgo = moment().subtract(30, 'd');
  if (!a.completed_at) return false;
  return moment(a.completed_at).isBefore(thirtyDaysAgo);
}

const CompletedExtra = ({tech, order, setFinished}) => {
  const [note, setNote] = useState("");
  const a = order.assignments[0];
  const activeTech = tech.id === a.tech_id;

  if (canCallback(order)) return <div />

  return <Popconfirm title={callBackNote(note, setNote)}
                      okText="Confirm"
                      okButtonProps={{disabled: note.length <= 5}}
                      onConfirm={() => confirmCallback(a.id, note, setFinished)}>
    <span className="text-danger">Callback</span>
  </Popconfirm>
}

export {
  UnassignedExtra,
  AssignedExtra,
  CompletedExtra
}
