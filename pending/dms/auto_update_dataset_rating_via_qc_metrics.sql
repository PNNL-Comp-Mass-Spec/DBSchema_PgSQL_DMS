--
CREATE OR REPLACE PROCEDURE public.auto_update_dataset_rating_via_qc_metrics
(
    _campaignName text = 'QC-Shew-Standard',
    _experimentExclusion text = '%Intact%',
    _datasetCreatedMinimum timestamp = '2000-01-01'::timestamp,
    _infoOnly boolean = true,
    INOUT _message text = ''
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
    _myRowCount int := 0;
    _thresholdP_2A int := 250;
    _thresholdP_2C int := 100;
BEGIN
    ----------------------------------------------
    -- Validate the Inputs
    ----------------------------------------------
    --
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
    _message := '';

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
         INNER JOIN t_dataset_rating_name DTN
           ON DS.dataset_type_ID = DTN.DST_Type_ID
    WHERE DS.dataset_rating_id = 5 AND
          DQC.p_2a < _thresholdP_2A AND      -- Number of tryptic peptides; total spectra count
          DQC.p_2c < _thresholdP_2C AND      -- Number of tryptic peptides; unique peptide count
          DTN.Dataset_Type LIKE '%msn%' AND
          DS.created >= _datasetCreatedMinimum AND
          C.campaign LIKE _campaignName AND
          NOT E.experiment LIKE _experimentExclusion
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        -- Preview the datasets that would be updated

        SELECT C.campaign AS Campaign,
               InstName.instrument AS Instrument,
               DS.created AS Dataset_Created,
               DS.dataset AS Dataset,
               DTN.Dataset_Type AS Dataset_Type,
               DS.comment AS Comment,
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
             INNER JOIN t_dataset_rating_name DTN
               ON DS.dataset_type_ID = DTN.DST_Type_ID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Found ' || _myRowCount::text || ' dataset';
        If _myRowCount <> 1 Then
            _message := _message || 's';
        End If;
        _message := _message || ' with';

    Else
        -- Update the rating

        UPDATE DS
        SET DS_Comment = CASE WHEN DS_comment = '' THEN ''
                              ELSE format('%s; Not released: SMAQC P_2C = %s', DS_comment, DQC.P_2C::int);
                         END,
            dataset_rating_id = - 5
        FROM t_dataset DS
             INNER JOIN Tmp_DatasetsToUpdate U
               ON DS.dataset_id = U.dataset_id
             INNER JOIN t_dataset_qc DQC
               ON DS.dataset_id = DQC.dataset_id
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Changed ' || _myRowCount::text || ' dataset';
        If _myRowCount <> 1 Then
            _message := _message || 's';
        End If;
        _message := _message || ' to Not Released since';

    End If;

    _message := _message || ' P_2A below ' || _thresholdP_2A::text || ' and P_2C below ' || _thresholdP_2C::text;

    If _infoOnly Then
        RAISE INFO '%', _message;
    ElsIf _myRowCount > 0 Then
        Call post_log_entry ('Normal', _message, 'AutoUpdateDatasetRatingViaQCMetrics');
    End If;

    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_update_dataset_rating_via_qc_metrics IS 'AutoUpdateDatasetRatingViaQCMetrics';
