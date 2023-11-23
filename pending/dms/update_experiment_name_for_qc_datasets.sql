--
CREATE OR REPLACE PROCEDURE public.update_experiment_name_for_qc_datasets
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Assures that the dataset name associated with QC datasets matches the dataset name
**
**  Arguments:
**
**  Auth:   mem
**  Date:   08/09/2018 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int := 0;
    _dateStamp text;
    _currentExpID int := 0;
    _experiment text;
    _msg text;

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

    -- Format the date in the form 2022-10-25
    _dateStamp := to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD')

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_QCExperiments (
        ExpID int Not Null,
        Experiment text Not Null
    );

    CREATE UNIQUE INDEX IX_Tmp_QCExperiments ON Tmp_QCExperiments(ExpID);

    CREATE TEMP TABLE Tmp_DatasetsToUpdate (
        ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Dataset_ID int,
        OldExperiment text Not Null,
        NewExperiment text Not Null,
        NewExpID int Not Null,
        Ambiguous boolean Not Null
    );

    CREATE UNIQUE INDEX IX_Tmp_DatasetsToUpdate ON Tmp_DatasetsToUpdate(Dataset_ID, ID);

    ---------------------------------------------------
    -- Find the QC experiments to process
    -- This list is modelled after the list in UDF GetDatasetPriority
    ---------------------------------------------------

    INSERT INTO Tmp_QCExperiments (ExpID, experiment )
    SELECT exp_id, experiment
    FROM t_experiments
    WHERE (experiment SIMILAR TO 'QC[_-]Shew[_-][0-9][0-9][_-][0-9][0-9]' OR
           experiment SIMILAR TO 'QC[_-]ShewIntact[_-][0-9][0-9]%' OR
           experiment SIMILAR TO 'QC[_]Shew[_]TEDDY%' OR
           experiment SIMILAR TO 'QC[_]Mam%' OR
           experiment SIMILAR TO 'QC[_]PP[_]MCF-7%'
              ) AND created >= make_date(2018, 1, 1)

    FOR _experiment IN
        SELECT Experiment
        FROM Tmp_QCExperiments
        ORDER BY ExpID
    LOOP

        INSERT INTO Tmp_DatasetsToUpdate( Dataset_ID,
                                          OldExperiment,
                                          NewExperiment,
                                          NewExpID,
                                          Ambiguous )
        SELECT DS.dataset_id,
               E.experiment,
               _experiment,
               _currentExpID,
               false As Ambiguous
        FROM t_dataset DS
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
        WHERE dataset LIKE _experiment || '%' AND
              E.experiment <> _experiment AND
              Not E.experiment In ('QC_Shew_16_01_AutoPhospho', 'EMSL_48364_Chacon_Testing', 'UVPD_MW_Dependence')
    END LOOP;

    ---------------------------------------------------
    -- Look for duplicate datasets in Tmp_DatasetsToUpdate
    ---------------------------------------------------

    UPDATE Tmp_DatasetsToUpdate
    SET Ambiguous = true
    WHERE Dataset_ID IN ( SELECT DS.Dataset_ID
                          FROM Tmp_DatasetsToUpdate DS
                          GROUP BY DS.Dataset_ID
                          HAVING COUNT(DS.ID) > 1 );

    If Not Exists (Select * From Tmp_DatasetsToUpdate) Then
        RAISE INFO '%', 'No candidate datasets were found';
        RETURN;
    End If;

    If Not _infoOnly And Not Exists (SELECT Dataset_ID FROM Tmp_DatasetsToUpdate WHERE Not Ambiguous) Then
        RAISE INFO '%', 'Candidate datasets were found, but they are all ambiguous; see them with _infoOnly=true';
        RETURN;
    End If;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-80s %-60s %-60s %-17s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Dataset',
                            'Old_Experiment',
                            'New_Experiment',
                            'New_Experiment_ID'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '-----------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT DS.Dataset_ID,
                   DS.Dataset,
                   DTU.OldExperiment As Old_Experiment,
                   DTU.NewExperiment As New_Experiment,
                   DTU.NewExpID      As New_Experiment_ID
                   public.append_to_text(DS.comment,
                                         format('Switched experiment from %s to %s on %s', DTU.OldExperiment, DTU.NewExperiment, _dateStamp),
                                         _delimiter => '; ', _maxlength => 512) As Comment
            FROM t_dataset DS
                 INNER JOIN Tmp_DatasetsToUpdate DTU
                   ON DS.dataset_id = DTU.dataset_id
            WHERE Not DTU.Ambiguous
            ORDER BY DTU.NewExperiment, DTU.OldExperiment, dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Dataset,
                                _previewData.Old_Experiment,
                                _previewData.New_Experiment,
                                _previewData.New_Experiment_ID
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        If Exists (SELECT Dataset_ID FROM Tmp_DatasetsToUpdate WHERE Ambiguous) Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-80s %-60s %-60s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Dataset',
                                'Old_Experiment',
                                'New_Experiment',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DS.Dataset_ID,
                       DS.Dataset,
                       DTU.OldExperiment As Old_Experiment,
                       DTU.NewExperiment As New_Experiment,
                       'Ambiguous match' AS Comment
                FROM t_dataset DS
                     INNER JOIN Tmp_DatasetsToUpdate DTU
                       ON DS.dataset_id = DTU.dataset_id
                WHERE DTU.Ambiguous
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Dataset,
                                    _previewData.Old_Experiment,
                                    _previewData.New_Experiment,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;
    Else

        ---------------------------------------------------
        -- Update the experiments associated with the datasets
        ---------------------------------------------------

        UPDATE t_dataset
        SET exp_id = DTU.NewExpID,
            comment = public.append_to_text(DS.comment,
                                            format('Switched experiment from %s to %s on %s', DTU.OldExperiment, DTU.NewExperiment, _dateStamp),
                                            _delimiter => '; ', _maxlength => 512)
        FROM Tmp_DatasetsToUpdate DTU
        WHERE t_dataset.Dataset_ID = DTU.Dataset_ID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _msg := format('Updated the experiment name for %s %s', _updateCount, public.check_plural(_updateCount, 'QC dataset', 'QC datasets'));
        CALL post_log_entry ('Normal', _msg, 'Update_Experiment_Name_For_QC_Datasets');

    End If;

    DROP TABLE Tmp_QCExperiments;
    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_experiment_name_for_qc_datasets IS 'UpdateExperimentNameForQCDatasets';
