import React, {useEffect} from "react";
import {connect} from "react-redux";
import {
  Card, CardHeader, CardBody, Button,
} from "reactstrap";
import actions from "../../../actions";
import AccountDetails from "./accountDetails";
import Locks from "./locks";

const Account = ({account, tenant}) => {
  useEffect(() => {
    actions.getAccount(tenant.tenant_id);
  }, []);

  // For locks, our source of truth is the lock with the most recent updated_at timestamp
  const locks = account?.locks ? [...account.locks] : [];
  const sortedLocks = locks.sort((a, b) => b.updated_at > a.updated_at && 1 || -1);
  const latestLock = sortedLocks[0];

  return (
    <Card className="ml-3">
      <CardHeader className="d-flex justify-content-between align-items-center py-1 pr-1">
        Account
        <div className="d-flex">
          {account && <Locks account={account} latestLock={latestLock} />}
          {account && (
          <a className="btn btn-info ml-2" href={`/user_accounts/${account.id}`} target="_blank">
            Log In As
          </a>
          )}
        </div>
      </CardHeader>
      <CardBody className={account && "p-0"}>
        {!account && (
        <div>
          <p>No account exists for this user. Create one now?</p>
          <Button disabled={!tenant.email} color="success" onClick={actions.createAccount.bind(null, tenant.tenant_id)}>
            Create
          </Button>
          {!tenant.email && (
          <p>
            <small>Please enter an email address for this resident before creating an account</small>
          </p>
          )}
        </div>
        )}
        {account && <AccountDetails account={account} email={tenant.email} sortedLocks={sortedLocks} />}
      </CardBody>
    </Card>
  );
}

const mapStateToProps = ({account, tenant}) => ({account, tenant});
export default connect(mapStateToProps)(Account);
