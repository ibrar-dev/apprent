import React from "react";
import moment from 'moment';
import OrderExport from './orderExport';
import {dateTimeRender, unitRender, residentEmail, residentRender, alarmCode, priorities} from '../infoRenders';
import {titleize} from "../../../../../../utils";


//USED FOR NOTES
function uniqueAssignments(assignments) {
  return Array.from(new Set(assignments.map(a => a.id))).map(id => {
    return assignments.find(a => a.id == id)
  })
}

function getDateTime(item) {
  if (item.type) return item.inserted_at;
  return item.updated_at;
}

function parseTime(t) {
  return new Date(moment(getDateTime(t))).getTime()
}

function sortedStuff(notes, assignments, attachments) {
  let combined = [...notes, ...assignments, ...attachments];
  return combined.sort((a, b) => (parseTime(a) - parseTime(b)))
}

function attachmentRender(type, url) {
  if (type.includes("image")) return <img className={"img-fluid"} src={url} />
  // if (type.includes("pdf")) return <a href={url} target={"_blank"}>View PDF</a>
  return <span>Unable to export</span>
}

function getText(item) {
  if (item.content_type) return attachmentRender(item.content_type, item.url)
  if (item.text) return item.text;
  if (item.tech_comments) return item.tech_comments;
  return (
    <img
      className={"img-fluid"}
      src={`https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/prod/${item.id}/${item.image}`}
    />
  )
}

const NotesRender = ({order}) => {
  const assignments = order.assignments ? uniqueAssignments(order.assignments.filter(a => a.tech_comments)) : [];
  const sorted = sortedStuff(order.notes || [], assignments, order.attachments || []);
  return <div className="card">
    <div className="card-header">Notes and Comments</div>
    <div className="card-body">
      {sorted.length >= 0 && sorted.map(n => {
        return <div key={n.id} className="card">
          <div className="card-body">
            <h5 className="card-title">{n.creator || ""}: <small>{moment(getDateTime(n)).format("MM/DD/YY hh:mmA")}</small></h5>
            {getText(n)}
          </div>
        </div>
      })}
    </div>
  </div>
}
//END USED FOR NOTES

//STANDARD INFO TABLE
const StandardInfo = ({order}) => {
  return <>
    <tr>
      <th>Received</th>
      <td>{dateTimeRender(order.inserted_at)}</td>
      <th>Unit</th>
      <td>{unitRender(order.unit)}</td>
    </tr>
    <tr>
      <th>Resident</th>
      <td>{residentRender(order.tenant)}</td>
      <th>Email</th>
      <td>{residentEmail(order.tenant)}</td>
    </tr>
    <tr>
      <th>Pet In Unit</th>
      <td>{order.has_pet ? "Yes" : "No"}</td>
      <th>Entry Allowed</th>
      <td>{order.entry_allowed ? "Yes" : "No"}</td>
    </tr>
    <tr>
      <th>SMS Updates</th>
      <td>{order.allow_sms ? "Yes" : "No"}</td>
      <th>Alarm Code</th>
      <td>{alarmCode(order)}</td>
    </tr>
    <tr>
      <th>Priority</th>
      <td>{priorities[order.priority]}</td>
      <th>Category</th>
      <td>
        <span>
  				<small>{order.category.parent_name} - </small>
  				<b>{order.category.category}</b>
  			</span>
      </td>
    </tr>
  </>
}
//END STANDARD INFO TABLE`

const CallbackItem = ({order}) => {
	if (!order.assignments) return null
	const callbacks = order.assignments.filter(a => a.status === "callback");
	if (!callbacks.length) return null
	return callbacks.map(c => {
		return <tr span={4} key={c.id}>
      <th>Callback</th>
      <td><b>{c.tech}</b> on <b>{moment.utc(c.updated_at).local().format("MM/DD/YY h:mmA")}</b></td>
    </tr>
	})
}

//COMPLETION ROWS
const CompletedInfo = ({order}) => {
  if (!order.assignments) return null
	if (["completed"].includes(order.status)) {
		const a = order.assignments[0];
		return <tr>
			<th>Completion</th>
			<td colSpan={3}><b>{a.tech}</b> on <b>{moment.utc(a.completed_at).local().format("MM/DD/YY h:mmA")}</b></td>
		</tr>
	} else {
		return null;
	}
}

const RatedInfo = ({order}) => {
	if (!order.assignments) return null
	if (["completed"].includes(order.status)) {
		const a = order.assignments[0];
		const stars = a.rating;
		return <tr>
			<th>Rating</th>
			<td colSpan={3}>
				{!stars && ""}
				{stars && [...Array(a.rating)].map((e, i) => {
					return <i key={i} className="fas fa-star" />
				})}
			</td>
		</tr>
	} else {
		return null
	}
}

const CommentInfo = ({order}) => {
  if (!order.assignments) return null
	if (["completed"].includes(order.status)) {
		const a = order.assignments[0];
		return <tr>
			<th>Completion Time</th>
			<td colSpan={3}>{a.resident_comment}</td>
		</tr>
	} else {
		return null;
	}
}

const CompletionTime = ({order}) => {
	if (!order.assignments) return null
	if (["completed"].includes(order.status)) {
		const a = order.assignments[0];
		return <tr>
			<th>Completion Time</th>
			<td colSpan={3}>{moment(a.completed_at).utc().to(moment(a.inserted_at).utc(), true)}</td>
		</tr>
	} else {
		return null;
	}
}

const CompletionRows = ({order}) => {
  return <>
    <CompletedInfo order={order} />
    <CompletionTime order ={order} />
    <RatedInfo order={order} />
    <CommentInfo order={order} />
  </>
}
//END COMPLETION ROWS

//CANCELLATION ROWS
const CancelItem = ({order, field}) => {
  if (!order.cancellation) return null
	if (field === "time") {
      return <tr>
      <th>Cancellation Time</th>
      <td colSpan={3}>{moment().utc(order.cancellation[field]).local().format("MM/DD/YY h:mmA")}</td>
    </tr>
  } else {
    return <tr>
      <th>Cancellation {titleize(field)}</th>
      <td colSpan={3}>{order.cancellation[field]}</td>
    </tr>
  }
}

const CancellationRows = ({order}) => {
  return <>
    <CancelItem order={order} field={"reason"} />
    <CancelItem order={order} field={"admin"} />
    <CancelItem order={order} field={"time"} />
  </>
}
//END CANCELLATION ROWS
export {
  NotesRender,
  StandardInfo,
  CallbackItem,
  CompletionRows,
  CancellationRows,
  OrderExport
}
