--
-- Name: get_dataset_priority(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_priority(_datasetname text) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**       Determine if the dataset name warrants preferential processing priority
**
**       This procedure is used by add_new_dataset to auto-release QC_Shew and QC_Mam datasets
**
**       If either the dataset name or the experiment name matches one of the filters below,
**       this function will return 1 and add_new_dataset() will set the dataset rating to 5 (Released)
**
**  Arguments:
**     _datasetName     Dataset name
**
**  Returns:
**      0 for default priority, 1 for higher priority
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
**          12/14/2023 mem - Change _datasetName data type to text
**
*****************************************************/
DECLARE
    _result int2;
BEGIN

    If (_datasetName::citext SIMILAR TO 'QC[_][0-9][0-9]%' Or
        _datasetName::citext SIMILAR TO 'QC[_-]Shew[_-][0-9][0-9]%' Or
        _datasetName::citext SIMILAR TO 'QC[_-]ShewIntact%' Or
        _datasetName::citext SIMILAR TO 'QC[_]Shew[_]TEDDY%' Or
        _datasetName::citext SIMILAR TO 'QC[_]Mam%' Or
        _datasetName::citext SIMILAR TO 'QC[_]PP[_]MCF-7%'
       ) And Not _datasetName ILike '%-bad' Then
        _result := 1;
    Else
        _result := 0;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_dataset_priority(_datasetname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_priority(_datasetname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_priority(_datasetname text) IS 'GetDatasetPriority';

