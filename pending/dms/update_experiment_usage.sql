--
CREATE OR REPLACE PROCEDURE public.update_experiment_usage
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column last_used in t_experiments
**
**      Column last_used is used by LcmsNetDMSTools when retrieving recent experiments
**
**  Arguments:
**    _infoOnly
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   07/31/2015 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int := 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-10s %-70s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Exp_ID',
                            'Last_Used',
                            'Last_Used_ReqRun',
                            'Last_Used_Dataset'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----------',
                                     '----------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT E.Exp_ID,
                   E.Last_Used,
                   LookupRR.MostRecentUse AS Last_Used_ReqRun,
                   LookupDS.MostRecentUse AS Last_Used_Dataset
            FROM t_experiments E
                 LEFT OUTER JOIN ( SELECT E.exp_id,
                                          MAX(CAST(RR.created AS date)) AS MostRecentUse
                                   FROM t_experiments E
                                        INNER JOIN t_requested_run RR
                                          ON E.exp_id = RR.exp_id
                                   GROUP BY E.exp_id
                                 ) LookupRR
                   ON E.exp_id = LookupRR.exp_id
                 LEFT OUTER JOIN ( SELECT E.exp_id,
                                          MAX(CAST(DS.created AS date)) AS MostRecentUse
                                   FROM t_experiments E
                                        INNER JOIN t_dataset DS
                                          ON E.exp_id = DS.exp_id
                                   GROUP BY E.exp_id
                                 ) LookupDS
                   ON E.exp_id = LookupDS.exp_id
            WHERE LookupRR.MostRecentUse > E.last_used OR
                  LookupDS.MostRecentUse > E.last_used
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Exp_ID,
                                _previewData.Last_Used,
                                _previewData.Last_Used_ReqRun,
                                _previewData.Last_Used_Dataset
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update based on the most recent Requested Run
    ---------------------------------------------------

    UPDATE t_experiments Target
    SET last_used = LookupQ.MostRecentUse
    FROM ( SELECT E.exp_id,
                  MAX(CAST(RR.Created AS date)) AS MostRecentUse
           FROM t_experiments E
                INNER JOIN t_requested_run RR
                  ON E.exp_id = RR.exp_id
           GROUP BY E.exp_id
         ) LookupQ
    WHERE Target.exp_id = LookupQ.exp_id AND
          LookupQ.MostRecentUse > Target.Last_Used;

    ---------------------------------------------------
    -- Update based on the most recent Dataset
    ---------------------------------------------------

    UPDATE t_experiments Target
    SET last_used = LookupQ.MostRecentUse
    FROM ( SELECT E.exp_id,
                  MAX(CAST(DS.Created AS date)) AS MostRecentUse
           FROM t_experiments E
                INNER JOIN t_dataset DS
                  ON E.exp_id = DS.exp_id
           GROUP BY E.exp_id
           ) LookupQ
    WHERE Target.Exp_ID = LookupQ.Exp_ID AND
          LookupQ.MostRecentUse > Target.Last_Used;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    RAISE INFO 'Updated Last_Used date for % %', _updateCount, public.check_plural(_updateCount, 'experiment',  'experiments');

END
$$;

COMMENT ON PROCEDURE public.update_experiment_usage IS 'UpdateExperimentUsage';
