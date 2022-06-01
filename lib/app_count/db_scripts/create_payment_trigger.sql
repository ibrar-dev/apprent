CREATE TRIGGER payment_update_trigger
    AFTER INSERT OR UPDATE
    ON accounting__payments
    FOR EACH ROW
EXECUTE PROCEDURE post_payment_hook();