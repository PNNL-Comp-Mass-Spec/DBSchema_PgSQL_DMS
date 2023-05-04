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
**  Auth:   mem
**  Date:   08/09/2018 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dateStamp text;
    _continue boolean;
    _currentExpID int := 0;
    _experiment text;
    _msg text;
BEGIN
    -- Format the date in the form 2022-10-25
    _dateStamp := to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD')

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';
    _returnCode:= '';

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

    _continue := true;

    FOR _experiment IN
        SELECT Experiment
        FROM Tmp_QCExperiments
        ORDER BY ExpID
    LOOP

        INSERT INTO Tmp_DatasetsToUpdate( dataset_id,
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
    WHERE Dataset_ID IN ( SELECT Dataset_ID
                          FROM Tmp_DatasetsToUpdate

                          /********************************************************************************
                          ** This UPDATE query includes the target table name in the FROM clause
                          ** The WHERE clause needs to have a self join to the target table, for example:
                          **   UPDATE Tmp_DatasetsToUpdate
                          **   SET ...
                          **   FROM source
                          **   WHERE source.id = Tmp_DatasetsToUpdate.id;
                          ********************************************************************************/

                                                 ToDo: Fix this query

                          GROUP BY Dataset_ID
                          HAVING COUNT(*) > 1 )

    If Not Exists (Select * From Tmp_DatasetsToUpdate) Then
        RAISE INFO '%', 'No candidate datasets were found';
        RETURN;
    End If;

    If Not _infoOnly And Not Exists (Select * From Tmp_DatasetsToUpdate Where Not Ambiguous) Then
        RAISE INFO '%', 'Candidate datasets were found, but they are all ambiguous; see them with _infoOnly=true';
        RETURN;
    End If;

    If _infoOnly Then
        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------
        --

        -- ToDo: Convert this to RAISE INFO

        SELECT DS.dataset_id,
               DS.dataset AS Dataset,
               DTU.OldExperiment,
               DTU.NewExperiment,
               DTU.NewExpID,
               public.append_to_text(DS.comment,
                        format('Switched experiment from %s to %s on %s', DTU.OldExperiment, DTU.NewExperiment, _dateStamp),
                        0, ';', 512) As Comment

        FROM t_dataset DS
             INNER JOIN Tmp_DatasetsToUpdate DTU
               ON DS.dataset_id = DTU.dataset_id
        WHERE Not DTU.Ambiguous
        ORDER BY DTU.NewExperiment, DTU.OldExperiment, dataset_id

        If Exists (Select * From Tmp_DatasetsToUpdate Where Ambiguous) Then
            SELECT DS.dataset_id,
                   DS.dataset AS Dataset,
                   DTU.OldExperiment,
                   DTU.NewExperiment,
                   'Ambiguous match' AS "Comment"
            FROM t_dataset DS
                 INNER JOIN Tmp_DatasetsToUpdate DTU
                   ON DS.dataset_id = DTU.dataset_id
            WHERE DTU.Ambiguous

        End If;
    Else

        ---------------------------------------------------
        -- Update the experiments associated with the datasets
        ---------------------------------------------------
        --
        UPDATE t_dataset
        SET exp_id = DTU.NewExpID,
            comment = public.append_to_text(DS.comment,
                        format('Switched experiment from %s to %s on %s', DTU.OldExperiment, DTU.NewExperiment, _dateStamp),
                        0, ';', 512)
        FROM Tmp_DatasetsToUpdate DTU
        WHERE t_dataset.Dataset_ID = DTU.Dataset_ID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _msg := format('Updated the experiment name for %s %s', _myRowCount, public.check_plural(_myRowcount, 'QC dataset', 'QC datasets'));
        Call post_log_entry ('Normal', _msg, 'UpdateExperimentNameForQCDatasets');

    End If;

    DROP TABLE Tmp_QCExperiments;
    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_experiment_name_for_qc_datasets IS 'UpdateExperimentNameForQCDatasets';