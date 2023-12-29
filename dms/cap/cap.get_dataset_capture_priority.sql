--
-- Name: get_dataset_capture_priority(public.citext, public.citext); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_dataset_capture_priority(_datasetname public.citext, _instrumentgroup public.citext) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determine if the dataset warrants preferential processing priority for dataset capture
**      This procedure is used by make_new_tasks_from_dms to define the capture job priority
**
**      If the dataset name matches one of the filters below, the capture priority will be 2 instead of 4
**      Otherwise, if the instrument group matches one of the filters, the capture priority will be 6 instead of 4
**
**  Return values: 2 if high priority; 4 if medium priority, 6 if low priority
**
**  Auth:   mem
**  Date:   06/27/2019 mem - Initial version
**          06/24/2022 mem - Ported to PostgreSQL
**          08/24/2022 mem - Fix ElsIf typo
**          04/02/2023 mem - Rename procedure and functions
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _priority int;
BEGIN
    -- These dataset names are modeled after those in function public.get_dataset_priority
    If (_datasetName SIMILAR TO 'QC[_][0-9][0-9]%' Or
        _datasetName SIMILAR TO 'QC[_-]Shew[_-][0-9][0-9]%' Or
        _datasetName SIMILAR TO 'QC[_-]ShewIntact%' Or
        _datasetName SIMILAR TO 'QC[_]Shew[_]TEDDY%' Or
        _datasetName SIMILAR TO 'QC[_]Mam%' Or
        _datasetName SIMILAR TO 'QC[_]PP[_]MCF-7%'
       ) AND NOT _datasetName LIKE '%-bad' Then
         _priority := 2;
    ElsIf _instrumentGroup In ('TSQ', 'Bruker_FTMS', 'MALDI-Imaging') Then
        _priority := 6;
    Else
        _priority := 4;
    End If;

    RETURN _priority;
END
$$;


ALTER FUNCTION cap.get_dataset_capture_priority(_datasetname public.citext, _instrumentgroup public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_capture_priority(_datasetname public.citext, _instrumentgroup public.citext); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_dataset_capture_priority(_datasetname public.citext, _instrumentgroup public.citext) IS 'GetDatasetCapturePriority';

