--
-- Name: trigfn_t_experiments_after_delete_all(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiments_after_delete_all() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Prevents deleting all rows in t_experiments,
**      raising an exception if the calling process tries to do so
**
**  Auth:   mem
**  Date:   08/01/2022 mem - Ported to PostgreSQL
**          07/10/2023 mem - Use COUNT(exp_id) instead of COUNT(*)
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _newRowCount int;
    _deletedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    SELECT COUNT(exp_id)
    INTO _newRowCount
    FROM t_experiments;

    SELECT COUNT(*)
    INTO _deletedRowCount
    FROM deleted;

    -- RAISE NOTICE 'New row count: %, deleted rows: %', _newRowCount, _deletedRowCount;

    If _deletedRowCount > 0 And _newRowCount = 0 Then
        _message := format('Cannot delete all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _deletedRowCount, 't_experiments', 'trigfn_t_experiments_after_delete');

        RAISE EXCEPTION '%', _message;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiments_after_delete_all() OWNER TO d3l243;

