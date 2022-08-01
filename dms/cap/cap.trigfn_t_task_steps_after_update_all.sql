--
-- Name: trigfn_t_task_steps_after_update_all(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_task_steps_after_update_all() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Prevents updating all rows in the table
**
**  Auth:   mem
**  Date:   02/08/2011 mem - Initial version
**          07/08/2012 mem - Added row counts to the error message
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
    FROM OLD;

    SELECT COUNT(*)
    INTO _existingRowCount
    FROM cap.t_task_steps;

    -- RAISE NOTICE 'Existing row count: %, Updated row count: %', _existingRowCount, _updatedRowCount;

    If _updatedRowCount > 1 And _updatedRowCount >= _existingRowCount Then
        _message := format('Cannot update all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _updatedRowCount, 't_task_steps', 'trigfn_t_task_steps_after_update_all');

        RAISE EXCEPTION '%', _message;
        RETURN null;
    End If;

    RETURN NEW;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_steps_after_update_all() OWNER TO d3l243;

