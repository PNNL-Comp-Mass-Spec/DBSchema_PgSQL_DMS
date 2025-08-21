--
-- Name: trigfn_t_service_cost_rate_before_delete(); Type: FUNCTION; Schema: svc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION svc.trigfn_t_service_cost_rate_before_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Assures that table svc.t_service_use does not reference a cost rate row prior to its deletion
**
**  Auth:   mem
**  Date:   08/14/2025 mem - Initial release
**          08/20/2025 mem - Reference schema svc instead of cc
**
*****************************************************/
DECLARE
    _reportID int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    SELECT R.report_id
    INTO _reportID
    FROM svc.t_service_use U
         INNER JOIN svc.t_service_use_report R
           ON U.report_id = R.report_id
    WHERE R.cost_group_id   = OLD.cost_group_id AND
          U.service_type_id = OLD.service_type_id
    LIMIT 1;

    If FOUND Then
        _message := format('Cannot delete cost rate info for cost group %s and service type %s since referenced by service use report %s',
                           OLD.cost_group_id, OLD.service_type_id, _reportID);

        RAISE EXCEPTION '%', _message;
    End If;

    -- Return the OLD row, since this function is called by a "before delete" trigger
    -- If you return NULL here, the delete operation is silently cancelled
    RETURN OLD;
END
$$;


ALTER FUNCTION svc.trigfn_t_service_cost_rate_before_delete() OWNER TO d3l243;

