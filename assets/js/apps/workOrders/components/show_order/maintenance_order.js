import React, {useEffect, useState} from 'react';
import {useParams, useHistory} from 'react-router-dom';
import axios from 'axios';
import {Skeleton, Card, Row, Col, Divider, Space} from "antd";
import {MobileTwoTone, CarTwoTone} from "@ant-design/icons";
import snackbar from '../../../../components/snackbar';
import {pageHeader, IconButton, PDFExport, ConfirmationIconButton,
  UnassignedDescription, AssignedDescription, CompletedDescription, CancelledDescription} from "./renderers";
import {OrderExport} from './renderers/exportRenders';

const totalNotes = (order) => {
  if (!order.notes || !order.attachments) return 0 
  return order.notes.length || 0 + order.attachments.length || 0
}

function canEdit(order) {
  return order.status === "unassigned" || order.status === "assigned"
}

function getDataForExport(order) {
  return <OrderExport order={order} />
}

function showOrder() {
  const [order, setOrder] = useState(null);
  const [fetching, setFetching] = useState(false);
  const [action, setAction] = useState("technicians")
  const [changed, setChanged] = useState(false);
  const [edit, setEdit] = useState(false);
  const {id} = useParams();
  const history = useHistory();

  const fetchOrder = async () => {
    setFetching(true);
    const promise = axios.get(`/api/orders/${id}?new`);
    promise.then(r => setOrder(r.data));
    promise.catch(() => snackbar({message: `Unable to find Maintenance Request`, args: {type: "warn"}}));
    promise.finally(() => setFetching(false))
  }

  const updateOrder = (workOrder) => {
    const promise = axios.patch(`/api/orders/${order.id}`, {workOrder});
    promise.then(() => setChanged(true));
  }

  useEffect(() => {
    fetchOrder();
  }, []);

  useEffect(() => {
    if (changed) {
      fetchOrder()
      setChanged(false);
    }
  }, [changed])

  if (fetching || !order) return <Skeleton active={true} paragraph={{paragraph: 10, width: '100%'}} />

  if (order) return <Row className={"w-100"}>
    <Card className={"w-100"} title={pageHeader(order, history.length > 1, () => history.goBack())}>
      <Row gutter={[0, 16]}>
        <Col flex={"auto"}>
          <Divider orientation="left" style={{ color: '#333', fontWeight: 'normal' }}>
            Actions
          </Divider>
          <Row justify={"space-between"}>
            <IconButton onClick={() => setAction("technicians")} title={"Assignment"} icon={`fas text-apprent fa-user-alt`} />
            <IconButton onClick={() => setAction("notes")} badge={totalNotes(order)} title={"Notes"} icon={'fas text-apprent fa-comments'} />
            <IconButton onClick={() => setAction("parts")} badge={order.parts.length} title={"Parts"} icon={'fas text-apprent fa-tools'} />
            <PDFExport data={getDataForExport(order)} fileName={`${order.ticket}_${order.status}.pdf`} />
            <IconButton disabled={!canEdit(order)} onClick={() => setEdit(!edit)} title={edit ? 'Editing' : 'Edit'} icon={'fas text-apprent fa-edit'} />
            <IconButton disabled={!canEdit(order)} onClick={() => setAction("cancel")} title={"Cancel Order"} icon={'far text-danger fa-window-close'} />
          </Row>
        </Col>
      </Row>
      <Row gutter={[0, 16]}>
        {order.status === "unassigned" && <UnassignedDescription order={order}
                                          action={action}
                                          edit={edit}
                                          setAction={setAction}
                                          setChanged={setChanged} />}
        {order.status === "assigned" && <AssignedDescription order={order}
                                          action={action}
                                          edit={edit}
                                          setAction={setAction}
                                          setChanged={setChanged} />}
        {order.status === "completed" && <CompletedDescription order={order}
                                          action={action}
                                          edit={edit}
                                          setAction={setAction}
                                          setChanged={setChanged} />}
        {order.status === "cancelled" && <CancelledDescription order={order}
                                          action={action}
                                          edit={edit}
                                          setAction={setAction}
                                          setChanged={setChanged} />}
      </Row>
    </Card>
  </Row>
}

export default showOrder;
