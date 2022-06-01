CREATE TRIGGER charge_update_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON accounting__charges
    FOR EACH ROW
EXECUTE PROCEDURE post_charge_hook();