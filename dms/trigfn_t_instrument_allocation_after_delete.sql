--
-- Name: trigfn_t_instrument_allocation_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_instrument_allocation_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_instrument_allocation_updates for the deleted allocation entries
**
**  Auth:   mem
**  Date:   03/30/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_instrument_allocation_updates for each deleted row
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
           allocated_hours as allocated_hours_old,
           null AS allocated_hours_new,
           CASE WHEN COALESCE(comment, '') = ''
                THEN '(deleted)'
                ELSE format('(deleted); %s', comment)
           END AS comment,
           CURRENT_TIMESTAMP
    FROM deleted
    ORDER BY allocation_tag, proposal_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_instrument_allocation_after_delete() OWNER TO d3l243;

