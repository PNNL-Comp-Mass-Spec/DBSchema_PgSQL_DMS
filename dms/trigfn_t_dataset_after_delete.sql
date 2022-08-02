--
-- Name: trigfn_t_dataset_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Prevents deleting all rows in t_dataset,
**      raising an exception if the calling process tries to do so
**
**  Auth:   mem
**  Date:   08/01/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _newRowCount int;
    _deletedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    SELECT COUNT(*)
    INTO _newRowCount
    FROM public.t_dataset;

    SELECT COUNT(*)
    INTO _deletedRowCount
    FROM deleted;

    -- RAISE NOTICE 'New row count: %, deleted rows: %', _newRowCount, _deletedRowCount;

    If _deletedRowCount > 0 And _newRowCount = 0 Then
        _message := format('Cannot delete all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _deletedRowCount, 't_dataset', 'trigfn_t_dataset_after_delete');

        RAISE EXCEPTION '%', _message;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_after_delete() OWNER TO d3l243;

