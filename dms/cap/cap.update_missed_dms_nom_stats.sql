--
-- Name: update_missed_dms_nom_stats(boolean, text, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_missed_dms_nom_stats(IN _deletefromtableonsuccess boolean DEFAULT true, IN _datasetids text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Call public.update_dataset_nom_stats_xml for datasets that have info defined in cap.t_dataset_nom_stats_xml,
**      yet the dataset does not have a corresponding row in public.t_dataset_nom_stats
**
**  Arguments:
**    _deleteFromTableOnSuccess     When true, delete from cap.t_dataset_nom_stats_xml after storing the data in public.t_dataset_nom_stats
**    _datasetIDs                   Comma-separated list of dataset IDs
**    _message                      Status message
**    _returnCode                   Return code
**    _infoOnly                     When true, preview updates
**
**  Example usage:
**      CALL update_missed_dms_nom_stats (
**               _deleteFromTableOnSuccess => true,
**               _datasetIDs => '1465646, 1466280, 1466284',
**               _infoOnly => true);
**
**  Auth:   mem
**  Date:   03/28/2026 mem - Initial version
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _datasetsProcessed int := 0;
    _datasetID int;
    _logMsg text;
    _logMsgType text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _deleteFromTableOnSuccess := Coalesce(_deleteFromTableOnSuccess, true);
    _datasetIDs               := Trim(Coalesce(_datasetIDs, ''));
    _infoOnly                 := Coalesce(_infoOnly, false);

    --------------------------------------------
    -- Create a table to hold datasets to process
    --------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess (
        Dataset_ID int NOT NULL
    );

    CREATE INDEX IX_Tmp_DatasetsToProcess ON Tmp_DatasetsToProcess (Dataset_ID);

    --------------------------------------------
    -- Look for Datasets with entries in cap.t_dataset_nom_stats_xml but no rows in public.t_dataset_nom_stats
    --------------------------------------------

    INSERT INTO Tmp_DatasetsToProcess (dataset_id)
    SELECT Src.dataset_id
    FROM cap.t_dataset_nom_stats_xml Src
         LEFT OUTER JOIN public.t_dataset_nom_stats Target
           ON Src.dataset_id = Target.dataset_id
    WHERE Target.dataset_id Is Null;

    --------------------------------------------
    -- Possibly filter on _datasetIDs
    --------------------------------------------

    If _datasetIDs <> '' Then
        DELETE FROM Tmp_DatasetsToProcess
        WHERE NOT Dataset_ID IN (SELECT Value
                                 FROM public.parse_delimited_integer_list(_datasetIDs));
    End If;

    --------------------------------------------
    -- Delete any entries that don't exist in public.t_dataset
    --------------------------------------------

    DELETE FROM Tmp_DatasetsToProcess
    WHERE NOT EXISTS (SELECT DS.Dataset_ID
                      FROM public.t_dataset DS
                      WHERE DS.Dataset_ID = Tmp_DatasetsToProcess.Dataset_ID);
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Ignoring %s %s in cap.t_dataset_nom_stats_xml because %s exist in public.t_dataset',
                            _matchCount,
                            public.check_plural(_matchCount, 'dataset', 'datasets'),
                            public.check_plural(_matchCount, 'it does not', 'they do not'));

        CALL public.post_log_entry ('Info', _message, 'update_missed_dms_nom_stats', 'cap');

        --------------------------------------------
        -- Delete any entries in cap.t_dataset_nom_stats_xml that were cached over 7 days ago and do not exist in public.t_dataset
        --------------------------------------------

        DELETE FROM cap.t_dataset_nom_stats_xml
        WHERE Cache_Date < CURRENT_TIMESTAMP - Interval '7 days' AND
              NOT EXISTS (SELECT DS.Dataset_ID
                          FROM public.t_dataset DS
                          WHERE DS.Dataset_ID = cap.t_dataset_nom_stats_xml.Dataset_ID);
    End If;

    --------------------------------------------
    -- Process each of the datasets in Tmp_DatasetsToProcess
    --------------------------------------------

    FOR _datasetID IN
        SELECT Dataset_ID
        FROM Tmp_DatasetsToProcess
        ORDER BY Dataset_ID
    LOOP
        CALL cap.update_dms_nom_stats_xml (
                    _datasetID,
                    _deleteFromTableOnSuccess,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _infoOnly   => _infoOnly);

        If Coalesce(_returnCode, '') <> '' Then
            If Coalesce(_message, '') = '' Then
                _logMsg := format('update_dms_nom_stats_xml returned error code %s for Dataset ID %s', _returnCode, _datasetID);
            Else
                _logMsg := format('update_dms_nom_stats_xml error: %s', _message);
            End If;

            If _infoOnly Then
                RAISE INFO '%', _logMsg;
            Else
                CALL public.post_log_entry (_logMsgType, _logMsg, 'update_missed_dms_nom_stats', 'cap', _duplicateEntryHoldoffHours => 22, _logErrorsToPublicLogTable => false);
            End If;
        End If;

        _datasetsProcessed := _datasetsProcessed + 1;
    END LOOP;

    If _infoOnly Then
        _message := format('Dataset NOM stats XML updates are pending for %s %s',
                            _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'));
    Else
        _message := format('Processed dataset NOM stats XML for %s %s (_deleteFromTableOnSuccess = %s)',
                            _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'),
                            CASE WHEN _deleteFromTableOnSuccess THEN 'true' ELSE 'false' END);
    End If;

    RAISE INFO '';
    RAISE INFO '%', _message;

    DROP TABLE Tmp_DatasetsToProcess;
END
$$;


ALTER PROCEDURE cap.update_missed_dms_nom_stats(IN _deletefromtableonsuccess boolean, IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

