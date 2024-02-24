--
-- Name: trigfn_t_instrument_allocation_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_instrument_allocation_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_instrument_allocation_updates for each updated allocation entry
**      Renames entries in t_file_attachment
**
**  Auth:   mem
**  Date:   03/31/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_instrument_allocation_updates (
        allocation_tag,
        proposal_id,
        fiscal_year,
        allocated_hours_old,
        allocated_hours_new,
        comment,
        entered
    )
    SELECT NEW.allocation_tag,
           NEW.proposal_id,
           NEW.fiscal_year,
           OLD.allocated_hours as allocated_hours_old,
           NEW.allocated_hours as allocated_hours_new,
           COALESCE(NEW.comment, '') AS comment,
           CURRENT_TIMESTAMP
    WHERE OLD.allocation_tag = NEW.allocation_tag AND    -- allocation_tag is never null
          OLD.proposal_id    = NEW.proposal_id;          -- proposal_id is never null

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_instrument_allocation_after_update() OWNER TO d3l243;

