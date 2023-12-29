--
-- Name: get_hplc_run_dataset_list(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_hplc_run_dataset_list(_hplcrunid integer, _returntype text DEFAULT 'name'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of datasets for given Prep LC run ID
**
**  Arguments:
**    _hplcRunId    Prep LC run ID
**    _returnType   If 'name', return dataset names, otherwise return dataset IDs
**
**  Return value: comma-separated list of dataset names or dataset IDs
**
**  Auth:   grk
**  Date:   09/29/2012
**          06/21/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    If Coalesce(_returnType, '') = 'name' Then
        SELECT string_agg(DS.dataset, ', ' ORDER BY DS.dataset)
        INTO _result
        FROM t_prep_lc_run_dataset AS PrepLC
             INNER JOIN t_dataset AS DS
               ON PrepLC.Dataset_ID = DS.Dataset_ID
        WHERE PrepLC.prep_lc_run_id = _hplcRunId;
    Else
        SELECT string_agg(DS.dataset_id::text, ', ' ORDER BY DS.dataset_id)
        INTO _result
        FROM t_prep_lc_run_dataset AS PrepLC
             INNER JOIN t_dataset AS DS
               ON PrepLC.Dataset_ID = DS.Dataset_ID
        WHERE PrepLC.prep_lc_run_id = _hplcRunId;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_hplc_run_dataset_list(_hplcrunid integer, _returntype text) OWNER TO d3l243;

