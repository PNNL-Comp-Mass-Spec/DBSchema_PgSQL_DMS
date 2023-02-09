--
-- Name: trigfn_t_requested_run_batches_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_requested_run_batches_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column request_name_code for requested runs
**      associated with the updated batches
**
**  Auth:   mem
**  Date:   08/05/2010 mem - Initial version
**          08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**          06/27/2022 mem - No longer pass the username of the batch owner to GetRequestedRunNameCode
**          08/01/2022 mem - Update column Updated_By
**          08/06/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**          02/08/2023 mem - Switch from PRN to username
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_requested_run
    SET request_name_code = public.get_requested_run_name_code(
                                        request_name, created, requester_username,
                                        batch_id, NEW.batch, NEW.created,
                                        request_type_id, separation_group)
    WHERE t_requested_run.batch_id = NEW.batch_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_batches_after_update() OWNER TO d3l243;

