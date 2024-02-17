--
-- Name: get_datasets_with_flanking_qcs(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_datasets_with_flanking_qcs(_startdate timestamp without time zone, _enddate timestamp without time zone) RETURNS TABLE(dataset public.citext, acq_time_start timestamp without time zone, lc_column_id integer, instrument public.citext, qc_dataset public.citext, subsequent_run integer, proximity_rank integer, diff_days numeric)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the flanking QC datasets for each non-QC dataset with an acquisition time between _startDate and _endDate
**      Looks for QC datasets acquired within 32 days of the dataset's acquisition start time
**
**  Auth:   mem
**  Date:   07/11/2022 mem - Initial release (based on view V_Datasets_With_Flanking_QCs)
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _qcStartDate timestamp;
    _qcEndDate timestamp;
BEGIN

    _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - Interval '7 days');
    _endDate := Coalesce(_endDate, _startDate + Interval '1 day');

    _qcStartDate := _startDate - Interval '32 days';
    _qcEndDate := _endDate + Interval '32 days';

    RETURN QUERY
    SELECT RankQ.Dataset,
           RankQ.Acq_Time_Start,
           RankQ.LC_Column_ID,
           InstName.instrument,
           RankQ.QC_Dataset,
           RankQ.Subsequent_Run,
           RankQ.Proximity_Rank::int,
           RankQ.Diff_Days
    FROM ( SELECT LookupQ.Dataset,
                  LookupQ.Acq_Time_Start,
                  LookupQ.LC_Column_ID,
                  LookupQ.Instrument_id,
                  LookupQ.QC_Dataset,
                  LookupQ.Diff_Hours / 24.0 AS Diff_Days,
                  LookupQ.Subsequent_Run,
                  Row_Number() OVER (PARTITION BY LookupQ.Dataset, LookupQ.Subsequent_Run ORDER BY Abs(LookupQ.Diff_Hours)) AS Proximity_Rank
           FROM ( SELECT DS.Dataset,
                         COALESCE(DS.Acq_Time_Start, DS.created) AS Acq_Time_Start,
                         DS.LC_Column_ID,
                         DS.Instrument_id,
                         QCDatasets.dataset AS QC_Dataset,
                         extract(epoch FROM (QCDatasets.Acq_Time - COALESCE(DS.Acq_Time_Start, DS.created))) / 3600.0 AS Diff_Hours,
                         CASE WHEN (extract(epoch FROM QCDatasets.Acq_Time - COALESCE(DS.Acq_Time_Start, DS.created))) < 0
                         THEN 0
                         ELSE 1
                         END AS Subsequent_Run
                  FROM public.t_dataset DS
                       INNER JOIN ( SELECT QCD.dataset,
                                           COALESCE(QCD.Acq_Time_Start, QCD.created) AS Acq_Time,
                                           QCD.instrument_id,
                                           QCD.lc_column_ID
                                    FROM public.t_dataset QCD
                                    WHERE (QCD.dataset LIKE 'qc_shew%' OR
                                           QCD.dataset LIKE 'qc_mam%' OR
                                           QCD.dataset LIKE 'qc_pp_mcf%') AND
                                          COALESCE(QCD.Acq_Time_Start, QCD.created) BETWEEN _qcStartDate AND _qcEndDate
                                  ) QCDatasets
                         ON DS.instrument_id = QCDatasets.instrument_id AND
                            DS.lc_column_ID = QCDatasets.lc_column_ID AND
                            DS.dataset <> QCDatasets.dataset
                  WHERE COALESCE(DS.Acq_Time_Start, DS.created) BETWEEN _startDate And _EndDate
                 ) LookupQ
       ) RankQ
         INNER JOIN public.t_instrument_name InstName
           ON InstName.Instrument_ID = RankQ.instrument_id
    WHERE RankQ.Proximity_Rank <= 4
    ORDER BY RankQ.Dataset, RankQ.Diff_Days;

END
$$;


ALTER FUNCTION public.get_datasets_with_flanking_qcs(_startdate timestamp without time zone, _enddate timestamp without time zone) OWNER TO d3l243;

