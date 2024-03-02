--
-- Name: update_experiment_usage(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_experiment_usage(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update column last_used in t_experiments
**
**      Column last_used is used by LcmsNetDMSTools when retrieving recent experiments
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   07/31/2015 mem - Initial version
**          03/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCountRR int;
    _updateCountDS int;
    _updateCount int;

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
        RAISE INFO '';
        RAISE INFO 'Looking for experiments to update';

        CREATE TEMP TABLE Tmp_ExperimentsToUpdate (
            Exp_ID int NOT NULL,
            Last_Used date,
            Last_Used_ReqRun date,
            Last_Used_Dataset date
        );

        INSERT INTO Tmp_ExperimentsToUpdate (Exp_ID, Last_Used, Last_Used_ReqRun, Last_Used_Dataset)
        SELECT E.Exp_ID,
               E.Last_Used,
               LookupRR.MostRecentUse AS Last_Used_ReqRun,
               LookupDS.MostRecentUse AS Last_Used_Dataset
        FROM t_experiments E
             LEFT OUTER JOIN (SELECT RR.exp_id,
                                     MAX(CAST(RR.created AS date)) AS MostRecentUse
                              FROM t_requested_run RR
                              GROUP BY RR.exp_id
                             ) LookupRR
               ON E.exp_id = LookupRR.exp_id
             LEFT OUTER JOIN (SELECT DS.exp_id,
                                     MAX(CAST(DS.created AS date)) AS MostRecentUse
                              FROM t_dataset DS
                              GROUP BY DS.exp_id
                             ) LookupDS
               ON E.exp_id = LookupDS.exp_id
        WHERE LookupRR.MostRecentUse > E.last_used OR
              LookupDS.MostRecentUse > E.last_used
        ORDER BY E.Exp_ID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount = 0 Then
            RAISE INFO 'Last_used date is already up-to-date for all experiments';

            DROP TABLE Tmp_ExperimentsToUpdate;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-11s %-17s %-18s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Exp_ID',
                            'Last_Used',
                            'Last_Used_ReqRun',
                            'Last_Used_Dataset',
                            'Experiment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----------',
                                     '----------------',
                                     '------------------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT U.Exp_ID,
                   U.Last_Used,
                   U.Last_Used_ReqRun,
                   U.Last_Used_Dataset,
                   E.Experiment
            FROM Tmp_ExperimentsToUpdate U
                 INNER JOIN T_Experiments E
                   ON U.Exp_ID = E.Exp_ID
            ORDER BY U.Exp_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Exp_ID,
                                _previewData.Last_Used,
                                _previewData.Last_Used_ReqRun,
                                _previewData.Last_Used_Dataset,
                                _previewData.Experiment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_ExperimentsToUpdate;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update based on the most recent Requested Run
    ---------------------------------------------------

    UPDATE t_experiments Target
    SET last_used = LookupQ.MostRecentUse
    FROM ( SELECT RR.exp_id,
                  MAX(CAST(RR.Created AS date)) AS MostRecentUse
           FROM t_requested_run RR
           GROUP BY RR.exp_id
         ) LookupQ
    WHERE LookupQ.exp_id = Target.exp_id AND
          LookupQ.MostRecentUse > Target.Last_Used;
    --
    GET DIAGNOSTICS _updateCountRR = ROW_COUNT;

    ---------------------------------------------------
    -- Update based on the most recent Dataset
    ---------------------------------------------------

    UPDATE t_experiments Target
    SET last_used = LookupQ.MostRecentUse
    FROM ( SELECT DS.exp_id,
                  MAX(CAST(DS.Created AS date)) AS MostRecentUse
           FROM t_dataset DS
           GROUP BY DS.exp_id
           ) LookupQ
    WHERE LookupQ.Exp_ID = Target.Exp_ID AND
          LookupQ.MostRecentUse > Target.Last_Used;
    --
    GET DIAGNOSTICS _updateCountDS = ROW_COUNT;

    _updateCount := _updateCountRR + _updateCountDS;

    RAISE INFO '';

    If _updateCount > 0 Then
        RAISE INFO 'Updated last_used date for % %', _updateCount, public.check_plural(_updateCount, 'experiment',  'experiments');
    Else
        RAISE INFO 'Last_used date is already up-to-date for all experiments';
    End If;

END
$$;


ALTER PROCEDURE public.update_experiment_usage(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_experiment_usage(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_experiment_usage(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateExperimentUsage';

