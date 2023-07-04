--
CREATE OR REPLACE PROCEDURE public.auto_update_dataset_rating_via_qc_metrics
(
    _campaignName text = 'QC-Shew-Standard',
    _experimentExclusion text = '%Intact%',
    _datasetCreatedMinimum timestamp = '2000-01-01'::timestamp,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for Datasets that have low QC metric values
**      and auto-updates their rating to Not_Released
**
**      If one more more entries is found, updates _matchingUsername and _matchingUserID for the first match
**
**  Arguments:
**    _campaignName   Campaign name to filter on; filter uses Like so the name can contain a wild card
**
**  Auth:   mem
**  Date:   10/18/2012
**          01/16/2014 mem - Added parameter _experimentExclusion
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _thresholdP_2A int := 250;
    _thresholdP_2C int := 100;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the Inputs
    ----------------------------------------------

    -- Do not allow _campaignName to be blank
    _campaignName := Coalesce(_campaignName, '');
    If _campaignName = '' Then
        _campaignName := 'QC-Shew-Standard';
    End If;

    _experimentExclusion := Coalesce(_experimentExclusion, '');
    If _experimentExclusion = '' Then
        _experimentExclusion := 'FakeNonExistentExperiment';
    End If;

    _datasetCreatedMinimum := Coalesce(_datasetCreatedMinimum, make_date(2000, 1, 1));
    _infoOnly := Coalesce(_infoOnly, false);

    CREATE TEMP TABLE Tmp_DatasetsToUpdate (
        Dataset_ID int not null
    )

    CREATE INDEX IX_Tmp_DatasetsToUpdate ON Tmp_DatasetsToUpdate (Dataset_ID)

    ----------------------------------------------
    -- Find Candidate Datasets
    ----------------------------------------------

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
          DSType.Dataset_Type LIKE '%msn%' AND
          DS.created >= _datasetCreatedMinimum AND
          C.campaign LIKE _campaignName AND
          NOT E.experiment LIKE _experimentExclusion;

    If _infoOnly Then

        -- Preview the datasets that would be updated

        -- ToDo: Show this info using RAISE INFO

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---',
                                     '---',
                                     '---',
                                     '---',
                                     '---'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        _updateCount := 0;

        FOR _previewData IN
            SELECT C.Campaign,
                   InstName.Instrument,
                   DS.Dataset_Created,
                   DS.Dataset,
                   DSType.Dataset_Type,
                   DS.Comment,
                   DQC.P_2A,
                   DQC.P_2C
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
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Campaign,
                                _previewData.Instrument,
                                _previewData.Dataset_Created,
                                _previewData.Dataset,
                                _previewData.Dataset_Type,
                                _previewData.Comment,
                                _previewData.P_2A,
                                _previewData.P_2C
                               );

            RAISE INFO '%', _infoData;
            
            _updateCount := _updateCount + 1;
        END LOOP;

        _message := format('Found %s %s with', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));

    Else
        -- Update the rating

        UPDATE DS
        SET Comment = CASE WHEN Comment = '' THEN ''
                           ELSE format('%s; Not released: SMAQC P_2C = %s', Comment, DQC.P_2C);
                      END,
            dataset_rating_id = - 5
        FROM t_dataset DS
             INNER JOIN Tmp_DatasetsToUpdate U
               ON DS.dataset_id = U.dataset_id
             INNER JOIN t_dataset_qc DQC
               ON DS.dataset_id = DQC.dataset_id;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Changed %s %s to Not Released since', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));

    End If;

    _message := format('%s P_2A below %s and P_2C below %s', _message, _thresholdP_2A, _thresholdP_2C);

    If _infoOnly Then
        RAISE INFO '%', _message;
    ElsIf _updateCount > 0 Then
        CALL post_log_entry ('Normal', _message, 'Auto_Update_Dataset_Rating_Via_QC_Metrics');
    End If;

    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_update_dataset_rating_via_qc_metrics IS 'AutoUpdateDatasetRatingViaQCMetrics';
