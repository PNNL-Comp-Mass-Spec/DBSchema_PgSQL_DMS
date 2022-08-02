--
-- Name: trigfn_t_experiment_plex_members_after_update_all(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiment_plex_members_after_update_all() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Prevents updating all rows in t_experiment_plex_members,
**      raising an exception if the calling process tries to do so
**
**  Auth:   mem
**  Date:   02/08/2011
**          09/11/2015 mem - Added support for the table being empty
**          08/01/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _existingRowCount int;
    _updatedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    SELECT COUNT(*)
    INTO _updatedRowCount
    FROM deleted;

    SELECT COUNT(*)
    INTO _existingRowCount
    FROM public.t_experiment_plex_members;

    -- RAISE NOTICE 'Existing row count: %, Updated row count: %', _existingRowCount, _updatedRowCount;

    If _updatedRowCount > 1 And _updatedRowCount >= _existingRowCount Then
        _message := format('Cannot update all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _updatedRowCount, 't_experiment_plex_members', 'trigfn_t_experiment_plex_members_after_update_all');

        RAISE EXCEPTION '%', _message;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiment_plex_members_after_update_all() OWNER TO d3l243;

