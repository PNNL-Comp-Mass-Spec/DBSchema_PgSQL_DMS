--
-- Name: trigfn_t_instrument_allocation_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_instrument_allocation_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_instrument_allocation_updates for the new allocation entries
**
**  Auth:   mem
**  Date:   03/30/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
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
    SELECT allocation_tag,
           proposal_id,
           fiscal_year,
           null AS allocated_hours_old,
           allocated_hours as allocated_hours_new,
           '' AS comment,
           CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.allocation_tag, inserted.proposal_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_instrument_allocation_after_insert() OWNER TO d3l243;

