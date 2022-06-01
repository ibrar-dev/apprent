CREATE OR REPLACE FUNCTION post_payment_hook()
    RETURNS TRIGGER AS
$payment_changed$
DECLARE
    new_lease_id     integer;
    ledger_lease_ids integer[];
BEGIN
    IF (TG_OP != 'DELETE' AND NEW.lease_id IS NULL)
    THEN
        SELECT target
        into new_lease_id
        FROM (
                 SELECT CASE
                            WHEN NEW.inserted_at < t.first_start_date THEN t.first_lease_id
                            WHEN NEW.inserted_at >= t.start_date THEN t.id
                            END target
                 FROM (
                          SELECT l.id,
                                 first_value(l.id) over (order by l.start_date)         first_lease_id,
                                 first_value(l.start_date) over (order by l.start_date) first_start_date,
                                 l.start_date
                          FROM tenants__tenants AS t
                                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                                   INNER JOIN leases__leases AS l ON p.lease_id = l.id
                                   INNER JOIN properties__units AS u ON u.id = l.unit_id
                          WHERE p.tenant_id = NEW.tenant_id) t
                 ORDER BY t.start_date DESC) tt
        WHERE tt.target IS NOT NULL
        LIMIT 1;

        IF (new_lease_id IS NOT NULL) THEN
            UPDATE accounting__payments
            SET lease_id = new_lease_id
            WHERE accounting__payments.id = NEW.id;
        END IF;
    END IF;

    SELECT ledgers.l_ids
    into ledger_lease_ids
    FROM (SELECT array_agg(l.id) l_ids
          FROM tenants__tenants AS t
                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                   INNER JOIN leases__leases AS l ON p.lease_id = l.id AND l.dirty = 'f'
                   INNER JOIN properties__units AS u ON u.id = l.unit_id
          GROUP BY u.id, t.id) ledgers WHERE coalesce(new_lease_id, NEW.lease_id) = ANY(ledgers.l_ids);

    PERFORM insert_receipts(ledger_lease_ids);

    RETURN NULL;
END
$payment_changed$ LANGUAGE plpgsql;
