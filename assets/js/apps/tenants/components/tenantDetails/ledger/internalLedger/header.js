import React, {useState} from 'react';
import moment from 'moment';
import {Button, Popover, PopoverBody} from 'reactstrap';
import actions from '../../../../actions';
import DateRangePicker from "../../../../../../components/dateRangePicker";
import confirmation from '../../../../../../components/confirmationModal';
import NewCharge from './newCharge';
import FileExport from "./fileExport";
import SODACharges from "./sodaCharges";
import MoveOutModal from '../../leases/moveOutModal';
import transactionsFromTenant from './transactionsFromTenant';

const changeDates = ({startDate, endDate}, setDates) => {
  const start = startDate ? moment(startDate) : null;
  if (startDate) start.startOf('day');
  const end = endDate ? moment(endDate) : null;
  if (endDate) end.endOf('day');
  const dates = {startDate: start, endDate: end};
  setDates({...dates});
}

const downloadLedger = (tenant, unit) => {
  const lease = tenant.leases.find(l => l.unit.number === unit.number);
  actions.downloadResidentLedger(tenant.id, lease.unit.id);
}

const unlockLedger = (lease) => {
  confirmation('Unlock this ledger?').then(() => actions.unlockLease(lease.id));
}

const internalLedgerHeader = (tenant, currentLease, {startDate, endDate}, setDates) => {
  const {ledgers} = transactionsFromTenant(tenant);
  const transactions = ledgers[currentLease.unit.number];

  const [modal, setModal] = useState(null);
  const [popoverOpen, setPopoverOpen] = useState(null);

  return (<div className="d-flex">
    <div className="d-inline-block">
      <DateRangePicker clearField={true} startDate={startDate} endDate={endDate}
                       onDatesChange={(dates) => changeDates(dates, setDates)}/>
    </div>
    <Button id="more-options-btn"
            className="m-0 ml-1 border-0 text-dark d-flex"
            onClick={() => setPopoverOpen(true)}
            style={{backgroundColor: popoverOpen ? '#bcc6d0' : 'transparent'}}>
      <i className="fas fa-ellipsis-v font-sze"/>
    </Button>
    <Popover placement="bottom" isOpen={popoverOpen} target="more-options-btn" className="popover-max"
             toggle={() => setPopoverOpen(false)}>
      <PopoverBody className="d-flex flex-column">
        {!currentLease.unit.closed && <>
          <Button color="info" outline onClick={setModal.bind(null, 'charge')} className="my-2">
            New Charges
          </Button>
          <Button color="info" outline onClick={setModal.bind(null, 'soda')} className="mb-2">
            Add Damages List
          </Button>
          {currentLease.actual_move_out &&
          <Button color="info" outline onClick={setModal.bind(null, 'moveOut')} className="mb-2">
            Lock Ledger
          </Button>}
        </>}
        {currentLease.closed &&
        <Button color="info" outline onClick={() => unlockLedger(currentLease)} className="mb-2">
          Unlock Ledger
        </Button>}
        <Button color="info" outline onClick={() => downloadLedger(tenant, currentLease.unit)} className="mb-2">
          Download Ledger
        </Button>
      </PopoverBody>
    </Popover>
    {modal === 'charge' && <NewCharge toggle={setModal} lease={currentLease}/>}
    {modal === 'pdf' && <FileExport toggle={setModal} transactions={transactions}/>}
    {modal === 'soda' && <SODACharges toggle={setModal}/>}
    {modal === 'moveOut' &&
    <MoveOutModal toggle={setModal} lease={currentLease} transactions={transactions}
                  tenant={tenant}/>}
  </div>)
}

export default internalLedgerHeader;