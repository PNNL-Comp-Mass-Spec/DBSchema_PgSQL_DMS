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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use IS DISTINCT FROM since both allocated_hours and comment could be null
    If OLD.allocated_hours IS DISTINCT FROM NEW.allocated_hours OR
       OLD.comment         IS DISTINCT FROM NEW.comment Then

        INSERT INTO t_instrument_allocation_updates( allocation_tag,
                                                     proposal_id,
                                                     fiscal_year,
                                                     allocated_hours_old,
                                                     allocated_hours_new,
                                                     comment,
                                                     entered )
        SELECT N.allocation_tag,
               N.proposal_id,
               N.fiscal_year,
               O.allocated_hours as allocated_hours_old,
               N.allocated_hours as allocated_hours_new,
               COALESCE(N.comment, '') AS comment,
               CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.allocation_tag = N.allocation_tag AND    -- allocation_tag is never null
                         O.proposal_id    = N.proposal_id;          -- proposal_id is never null

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_instrument_allocation_after_update() OWNER TO d3l243;

