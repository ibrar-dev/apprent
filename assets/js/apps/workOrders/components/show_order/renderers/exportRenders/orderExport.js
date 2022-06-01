import React from 'react';
import {NotesRender, StandardInfo, CallbackItem, CompletionRows, CancellationRows} from './index';
import moment from 'moment';
import {titleize} from '../../../../../../utils';

function assignedInfo(order) {
	if (["assigned", "completed"].includes(order.status)) {
		const a = order.assignments[0];
		return <tr>
			<th>Assignment</th>
			<td colSpan={3}><span>Assigned to <b>{a.tech}</b> by <b>{a.creator}</b> on <b>{moment.utc(a.inserted_at).local().format("MM/DD/YY h:mmA")}</b></span></td>
		</tr>
	} else {
		return null
	}
}

const HeaderTitle = ({order}) => {
	let unit = "";
	if (order.unit) unit = `Unit: ${order.unit.number}`;
	return <span>{order.property.name} <small>{unit} - {titleize(order.status)}</small></span>
}

const BlankRow = ({order}) => {
	if (order.status === "unassigned") {
		return null
	} else {
		return <tr><td colSpan={4}></td></tr>
	}
}

const OrderExport = ({order}) => {
  return <div className={"row"}>
    <div className="col-sm-12">
			<div className="card">
				<h4 className="card-header"><HeaderTitle order={order} /></h4>
				<table className="table table-bordered text-left">
			    <tbody>
			      {assignedInfo(order)}
						<CallbackItem order={order} />
						<CompletionRows order={order} />
						<CancellationRows order={order} />
						<BlankRow order={order} />
						<StandardInfo order={order} />
			    </tbody>
			  </table>
	      <div className="row">
	        <div className="col-sm-12">
	          <NotesRender order={order} />
	        </div>
	      </div>
			</div>
    </div>
  </div>
}

const styles = {
	icon: {
		fontSize: 24
	},
	label: {
		fontSize: 16
	},
	select: {
		width: '100%'
	}
}

export default OrderExport
