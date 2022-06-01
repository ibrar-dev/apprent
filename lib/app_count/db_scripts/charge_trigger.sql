CREATE OR REPLACE FUNCTION post_charge_hook()
    RETURNS TRIGGER AS
$charge_changed$
DECLARE
    lease_id         integer;
    ledger_lease_ids integer[];
BEGIN

    IF (TG_OP = 'DELETE')
    THEN
        lease_id = OLD.lease_id;
    ELSE
        lease_id = NEW.lease_id;
    END IF;

    SELECT ledgers.l_ids
    into ledger_lease_ids
    FROM (SELECT array_agg(l.id) l_ids
          FROM tenants__tenants AS t
                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                   INNER JOIN leases__leases AS l ON p.lease_id = l.id AND l.dirty = 'f'
                   INNER JOIN properties__units AS u ON u.id = l.unit_id
          GROUP BY u.id, t.id) ledgers
    WHERE lease_id = ANY (ledgers.l_ids);

    PERFORM insert_receipts(ledger_lease_ids);

    RETURN NULL;
END
$charge_changed$ LANGUAGE plpgsql;
