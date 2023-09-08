--
-- Name: get_dataset_priority(public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_priority(_datasetname public.citext) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**       Determines if the dataset name warrants preferential processing priority
**
**       This procedure is used by add_new_dataset to auto-release QC_Shew datasets
**
**       If either the dataset name or the experiment name matches one of the
**       filters below, the Dataset_Rating_ID is set to 5 (Released)
**
**  Return values: 0 for default priority, 1 for higher priority
**
**  Auth:   grk
**  Date:   02/10/2006
**          04/09/2007 mem - Added matching of QC_Shew datasets in addition to QC datasets (Ticket #430)
**          04/11/2008 mem - Added matching of SE_QC_Shew datasets in addition to QC datasets
**          05/12/2011 mem - Now excluding datasets that end in -bad
**          01/16/2014 mem - Added QC_ShewIntact datasets
**          12/18/2014 mem - Replace [_] with [_-]
**          05/07/2015 mem - Added QC_Shew_TEDDY
**          08/08/2018 mem - Added QC_Mam and QC_PP_MCF-7
**          06/27/2019 mem - Renamed from DatasetPreference to GetDatasetPriority
**          06/19/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _result int2;
BEGIN

    If (_datasetName SIMILAR TO 'QC[_][0-9][0-9]%' Or
        _datasetName SIMILAR TO 'QC[_-]Shew[_-][0-9][0-9]%' Or
        _datasetName SIMILAR TO 'QC[_-]ShewIntact%' Or
        _datasetName SIMILAR TO 'QC[_]Shew[_]TEDDY%' Or
        _datasetName SIMILAR TO 'QC[_]Mam%' Or
        _datasetName SIMILAR TO 'QC[_]PP[_]MCF-7%'
       ) And Not_datasetName Like '%-bad' Then
        _result := 1;
    Else
        _result := 0;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_dataset_priority(_datasetname public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_priority(_datasetname public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_priority(_datasetname public.citext) IS 'GetDatasetPriority';

