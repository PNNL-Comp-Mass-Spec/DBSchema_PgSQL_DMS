--
-- Name: auto_update_dataset_rating_via_qc_metrics(text, text, timestamp without time zone, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_update_dataset_rating_via_qc_metrics(IN _campaignname text DEFAULT 'QC-Shew-Standard'::text, IN _experimentexclusion text DEFAULT '%Intact%'::text, IN _datasetcreatedminimum timestamp without time zone DEFAULT '2000-01-01 00:00:00'::timestamp without time zone, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for 'Released' datasets that have low QC metric values; auto change their rating to 'Not Released'
**
**      Thresholds:
**        Number of tryptic peptides, total spectra count,  less than 250
**         and
**        Number of tryptic peptides, unique peptide count, less than 100
**
**  Arguments:
**    _campaignName             Campaign name to filter on; supports % as a wildcard
**    _experimentExclusion      Experiment name to exclude; supports % as a wildcard
**    _datasetCreatedMinimum    Dataset creation date threshold for selecting datasets to examine
**    _infoOnly                 When true, preview updates
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   10/18/2012
**          01/16/2014 mem - Added parameter _experimentExclusion
**          01/28/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _thresholdP_2A int;
    _thresholdP_2C int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------

    _campaignName          := Trim(Coalesce(_campaignName, ''));
    _experimentExclusion   := Trim(Coalesce(_experimentExclusion, ''));
    _datasetCreatedMinimum := Coalesce(_datasetCreatedMinimum, make_date(2000, 1, 1));
    _infoOnly              := Coalesce(_infoOnly, false);

    -- Do not allow _campaignName to be blank
    If _campaignName = '' Then
        _campaignName := 'QC-Shew-Standard';
    End If;

    If _experimentExclusion = '' Then
        _experimentExclusion := 'FakeNonExistentExperiment';
    End If;

    CREATE TEMP TABLE Tmp_DatasetsToUpdate (
        Dataset_ID int NOT NULL
    );

    CREATE INDEX IX_Tmp_DatasetsToUpdate ON Tmp_DatasetsToUpdate (Dataset_ID);

    ----------------------------------------------
    -- Find candidate datasets
    ----------------------------------------------

    _thresholdP_2A := 250;
    _thresholdP_2C := 100;

    INSERT INTO Tmp_DatasetsToUpdate (dataset_id)
    SELECT DS.dataset_id
    FROM t_dataset DS
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_dataset_qc DQC
           ON DS.dataset_id = DQC.dataset_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_campaign C
           ON E.campaign_id = C.campaign_id
         INNER JOIN t_dataset_type_name DSType
           ON DS.dataset_type_ID = DSType.dataset_type_id
    WHERE DS.dataset_rating_id = 5 AND
          DQC.p_2a < _thresholdP_2A AND      -- Number of tryptic peptides; total spectra count
          DQC.p_2c < _thresholdP_2C AND      -- Number of tryptic peptides; unique peptide count
          DS.created >= _datasetCreatedMinimum AND
          DSType.Dataset_Type ILIKE '%msn%' AND
          C.campaign          ILIKE _campaignName AND
          NOT E.experiment    ILIKE _experimentExclusion;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount = 0 Then
        _message := format('Did not find any matching datasets with P_2A below %s and P_2C below %s', _thresholdP_2A, _thresholdP_2C);

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_DatasetsToUpdate;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-60s %-25s %-12s %-20s %-80s %-15s %-75s %-8s %-8s';

        _infoHead := format(_formatSpecifier,
                            'Campaign',
                            'Instrument',
                            'Dataset_ID',
                            'Dataset_Created',
                            'Dataset',
                            'Dataset_Type',
                            'Comment',
                            'P_2A',
                            'P_2C'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------------------------------------------------------',
                                     '-------------------------',
                                     '------------',
                                     '--------------------',
                                     '--------------------------------------------------------------------------------',
                                     '---------------',
                                      '---------------------------------------------------------------------------',
                                     '--------',
                                     '--------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Substring(C.campaign, 1, 100) AS campaign,
                   InstName.instrument,
                   DS.dataset_id,
                   public.timestamp_text(DS.created) AS dataset_created,
                   DS.dataset,
                   DSType.dataset_type,
                   Substring(DS.comment, 1, 75) AS comment,
                   DQC.p_2a,
                   DQC.p_2c
            FROM t_dataset DS
                 INNER JOIN Tmp_DatasetsToUpdate U
                   ON DS.dataset_id = U.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN t_dataset_qc DQC
                   ON DS.dataset_id = DQC.dataset_id
                 INNER JOIN t_experiments E
                   ON DS.exp_id = E.exp_id
                 INNER JOIN t_campaign C
                   ON E.campaign_id = C.campaign_id
                 INNER JOIN t_dataset_type_name DSType
                   ON DS.dataset_type_ID = DSType.dataset_type_id
            ORDER BY DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.campaign,
                                _previewData.instrument,
                                _previewData.dataset_id,
                                _previewData.dataset_created,
                                _previewData.dataset,
                                _previewData.dataset_type,
                                _previewData.comment,
                                _previewData.p_2a,
                                _previewData.p_2c
                               );

            RAISE INFO '%', _infoData;

        END LOOP;

        _message := format('Found %s %s with', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));

    Else
        -- Update the rating

        UPDATE t_dataset DS
        SET comment = format('%sNot released: SMAQC P_2C = %s',
                             CASE WHEN comment = '' THEN ''
                                  ELSE comment || '; '
                             END,
                             DQC.P_2C),
            dataset_rating_id = -5  -- 'Not released'
        FROM Tmp_DatasetsToUpdate U
             INNER JOIN t_dataset_qc DQC
               ON U.dataset_id = DQC.dataset_id
        WHERE DS.dataset_id = U.dataset_id;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Changed %s %s to Not Released since', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));

    End If;

    _message := format('%s P_2A below %s and P_2C below %s', _message, _thresholdP_2A, _thresholdP_2C);

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO '%', _message;
    ElsIf _updateCount > 0 Then
        CALL post_log_entry ('Normal', _message, 'Auto_Update_Dataset_Rating_Via_QC_Metrics');
    End If;

    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;


ALTER PROCEDURE public.auto_update_dataset_rating_via_qc_metrics(IN _campaignname text, IN _experimentexclusion text, IN _datasetcreatedminimum timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_update_dataset_rating_via_qc_metrics(IN _campaignname text, IN _experimentexclusion text, IN _datasetcreatedminimum timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_update_dataset_rating_via_qc_metrics(IN _campaignname text, IN _experimentexclusion text, IN _datasetcreatedminimum timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AutoUpdateDatasetRatingViaQCMetrics';

