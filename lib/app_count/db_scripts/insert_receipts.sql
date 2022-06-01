CREATE OR REPLACE FUNCTION insert_receipts(lease_ids integer[])
    RETURNS VOID AS
$insert_receipts$
DECLARE
    receipt_ids      integer[];
    rent_account_ids integer[];
    extra_receipts   integer[];
BEGIN

    IF array_length(lease_ids, 1) = 0 OR lease_ids[1] IS NULL
    THEN
        RETURN;
    END IF;

    SELECT array_agg(a.id)
    into rent_account_ids
    FROM accounting__accounts a
    WHERE a.name = ANY (ARRAY ['Rent', 'HAPRent']);

    SELECT array_agg(r.id)
    into receipt_ids
    FROM accounting__receipts r
             LEFT JOIN accounting__charges c ON (c.id = r.charge_id OR c.id = r.concession_id)
             LEFT JOIN accounting__payments p ON p.id = r.payment_id
    WHERE c.lease_id = ANY (lease_ids)
       OR p.lease_id = ANY (lease_ids);

    DELETE FROM accounting__receipts r WHERE r.id = ANY (receipt_ids);

    WITH RECURSIVE
        rec(payment_id, concession_id, payment_balance, charge_id, charge_balance, amount, payments, charges, stop_date,
            start_date, stops, should_recurse, next_payments, next_charges)
            AS (
            SELECT CASE WHEN agg.payments[1][3] = 1 THEN agg.payments[1][1] END,
                   CASE WHEN agg.payments[1][3] = 2 THEN agg.payments[1][1] END,
                   GREATEST(agg.payments[1][2] - agg.charges[1][2], 0),
                   agg.charges[1][1],
                   GREATEST(agg.charges[1][2] - agg.payments[1][2], 0),
                   LEAST(agg.payments[1][2], agg.charges[1][2]),
                   CASE
                       WHEN agg.payments[1][2] <= agg.charges[1][2] THEN agg.payments[2:2147483647]
                       ELSE agg.payments END,
                   CASE
                       WHEN agg.charges[1][2] <= agg.payments[1][2] THEN agg.charges[2:2147483647]
                       ELSE agg.charges END,
                   to_timestamp(agg.stops[1])::date,
                   null::date,
                   agg.stops,
                   false,
                   CASE WHEN agg.payments[1][4] = agg.stops[1] THEN ARRAY []::numeric[] ELSE agg.payments[1:1] END,
                   CASE WHEN agg.charges[1][3] = agg.stops[1] THEN ARRAY []::numeric[] ELSE agg.charges[1:1] END
            FROM agg
            UNION ALL
            SELECT CASE WHEN rec.payments[1][3] = 1 THEN rec.payments[1][1] END,
                   CASE WHEN rec.payments[1][3] = 2 THEN rec.payments[1][1] END,
                   GREATEST(p_amount.amount - c_amount.amount, 0),
                   rec.charges[1][1],
                   GREATEST(c_amount.amount - p_amount.amount, 0),
                   LEAST(p_amount.amount, c_amount.amount),
                   CASE
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 AND
                            rec.payments[1][1] = (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                           THEN rec.next_payments || rec.payments[2:2147483647]
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 THEN rec.next_payments || rec.payments
                       WHEN p_amount.amount <= c_amount.amount THEN rec.payments[2:2147483647]
                       ELSE rec.payments END,
                   CASE
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 AND rec.charges[1][1] = rec.charge_id
                           THEN rec.next_charges || rec.charges[2:2147483647]
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 THEN rec.next_charges || rec.charges
                       WHEN c_amount.amount <= p_amount.amount THEN rec.charges[2:2147483647]
                       ELSE rec.charges END,
                   CASE WHEN rec.should_recurse THEN to_timestamp(rec.stops[2])::date ELSE rec.stop_date END,
                   CASE WHEN rec.should_recurse THEN rec.stop_date ELSE rec.start_date END,
                   CASE WHEN rec.should_recurse THEN rec.stops[2:2147483647] ELSE rec.stops END,
                   is_last_row.t,
                   CASE
                       WHEN is_last_row.t THEN ARRAY []::numeric[]
                       WHEN rec.payments[1][1] =
                            (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                           THEN rec.next_payments
                       WHEN rec.payments[1][4] = rec.stops[1] THEN rec.next_payments
                       ELSE rec.next_payments || rec.payments[1:1] END,
                   CASE
                       WHEN is_last_row.t THEN ARRAY []::numeric[]
                       WHEN rec.charges[1][1] = rec.charge_id THEN rec.next_charges
                       WHEN rec.charges[1][3] = rec.stops[1] THEN rec.next_charges
                       ELSE rec.next_charges || rec.charges[1:1] END
            FROM rec
                     JOIN LATERAL (SELECT CASE
                                              WHEN rec.charges[1][1] = rec.charge_id THEN rec.charge_balance
                                              ELSE rec.charges[1][2] END amount) c_amount
                          ON true
                     JOIN LATERAL (SELECT CASE
                                              WHEN rec.payments[1][1] =
                                                   (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                                                  THEN rec.payment_balance
                                              ELSE rec.payments[1][2] END amount) p_amount
                          ON true
                     JOIN LATERAL (SELECT CASE
                                              WHEN (array_length(rec.charges, 1) = 1 AND
                                                    c_amount.amount <= p_amount.amount) OR
                                                   (array_length(rec.payments, 1) = 1 AND
                                                    p_amount.amount <= c_amount.amount)
                                                  THEN
                                                  true
                                              ELSE false END t) is_last_row
                          ON true
            WHERE array_length(rec.charges, 1) > 0
              AND array_length(rec.payments, 1) > 0
        ),
        concessions AS (SELECT c.id, c.amount * -1, c.bill_date date, r.bill_date stop_date, 2 AS type
                        FROM accounting__charges c
                                 LEFT JOIN accounting__charges r ON c.reversal_id = r.id
                        WHERE c.amount < 0
                          AND c.lease_id = ANY (lease_ids)
                          AND c.reversal_id IS NULL
                          AND c.status != 'reversal'),
        payments AS (SELECT p.id, p.amount, p.inserted_at::date date, c.bill_date stop_date, 1 AS type
                     FROM accounting__payments p
                              LEFT JOIN accounting__charges c ON c.nsf_id = p.id
                     WHERE p.lease_id = ANY (lease_ids)
                       AND p.status != 'voided'),
        payers AS (
            SELECT *
            FROM payments
            WHERE payments.stop_date IS NULL
               OR payments.date != payments.stop_date
            UNION
            SELECT *
            FROM concessions
            WHERE concessions.stop_date IS NULL
               OR concessions.date != concessions.stop_date
        ),
        payments_concessions AS (SELECT array_agg(ARRAY [p.id, p.amount, p.type, EXTRACT(EPOCH FROM (p.stop_date))::integer]
                                                  ORDER BY EXTRACT(EPOCH FROM (p.date)) - p.type) p_ids,
                                        array_agg(EXTRACT(EPOCH FROM (p.stop_date))::integer)
                                        FILTER (WHERE p.stop_date IS NOT NULL)                    stops
                                 FROM payers p),
        charges AS (SELECT array_agg(ARRAY [c.id, c.amount, EXTRACT(EPOCH FROM (r.bill_date))::integer]
                                     ORDER BY c.bill_date,
                                         (CASE WHEN c.account_id = ANY (rent_account_ids) THEN 0 ELSE 1 END)
                               )                                  c_ids,
                           array_agg(EXTRACT(EPOCH FROM (r.bill_date))::integer)
                           FILTER (WHERE r.bill_date IS NOT NULL) stops
                    FROM accounting__charges c
                             LEFT JOIN accounting__charges r ON c.reversal_id = r.id
                    WHERE c.amount > 0
                      AND (c.bill_date != r.bill_date OR r.bill_date IS NULL)
                      AND c.lease_id = ANY (lease_ids)
                      AND c.nsf_id IS NULL
                      AND c.status != 'reversal'),
        agg AS (
            SELECT payments_concessions.p_ids                                                                     payments,
                   charges.c_ids                                                                                  charges,
                   ARRAY(SELECT DISTINCT unnest(array_cat(charges.stops, payments_concessions.stops)) ORDER BY 1) stops
            FROM payments_concessions
                     JOIN charges ON true
        )
    INSERT
    INTO accounting__receipts(payment_id, concession_id, charge_id, amount, start_date, stop_date, inserted_at,
                              updated_at)
    SELECT payment_id,
           concession_id,
           charge_id,
           amount,
           CASE WHEN bool_or(start_date IS NULL) THEN NULL ELSE min(start_date) END start_date,
           CASE WHEN bool_or(stop_date IS NULL) THEN NULL ELSE max(stop_date) END   stop_date,
           now()                                                                    inserted_at,
           now()                                                                    updated_at
    FROM rec
    WHERE charge_id IS NOT NULL
      AND (payment_id IS NOT NULL OR concession_id IS NOT NULL)
    GROUP BY payment_id, concession_id, charge_id, amount;

    SELECT array_agg(r.id)
    into extra_receipts
    FROM accounting__receipts r
             LEFT JOIN accounting__charges c ON (c.id = r.charge_id OR c.id = r.concession_id)
             LEFT JOIN accounting__payments p ON p.id = r.payment_id
             LEFT JOIN accounting__charges rev ON p.id = rev.nsf_id
             LEFT JOIN accounting__charges con ON con.id = r.concession_id
    WHERE (c.lease_id = ANY (lease_ids) OR p.lease_id = ANY (lease_ids))
      AND r.stop_date IS NULL
      AND (c.reversal_id IS NOT NULL OR con.reversal_id IS NOT NULL OR rev.nsf_id IS NOT NULL);

    DELETE FROM accounting__receipts r WHERE r.id = ANY (extra_receipts);
END
$insert_receipts$ LANGUAGE plpgsql;