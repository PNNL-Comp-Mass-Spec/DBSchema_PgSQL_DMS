--
-- Name: find_stale_myemsl_uploads(integer, boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.find_stale_myemsl_uploads(IN _staleuploaddays integer DEFAULT 45, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for unverified entries added to cap.t_myemsl_uploads over 45 ago (customize with _staleUploadDays)
**      For any that are found, sets error_code to 101 and posts an entry to cap.t_log_entries
**
**  Auth:   mem
**  Date:   05/20/2019 mem - Initial version
**          07/01/2019 mem - Log details of entries over 1 year old that will have error_code set to 101
**          07/08/2019 mem - Fix bug updating RetrySucceeded
**                         - Pass _logMessage to post_log_entry
**          10/11/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          04/27/2023 mem - Use boolean for data type name
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/12/2023 mem - Rename variables
**
*****************************************************/
DECLARE
    _foundRetrySuccessTasks boolean := false;
    _entryID int;
    _job int;
    _entryIDList text;
    _jobList text;
    _iteration int := 0;
    _updateCount int;
    _entryCountToLog int := 5;
    _uploadInfo record;
    _logMessage text;

    _formatSpecifier text := '%-12s %-17s %-10s %-10s %-10s %-10s %-15s %-20s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _staleUploadDays := Abs(Coalesce(_staleUploadDays, 45));
    _infoOnly := Coalesce(_infoOnly, false);

    If _staleUploadDays < 14 Then
        -- Require _staleUploadDays to be at least 14
        _staleUploadDays := 14;
    End If;

    ---------------------------------------------------
    -- Find and process stale uploads
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_StaleUploads (
        Entry_ID int Not Null,
        Job int Not Null,
        Dataset_ID int Not Null,
        Subdirectory text Not Null,
        Entered timestamp,
        RetrySucceeded boolean
    );

    INSERT INTO Tmp_StaleUploads( entry_id,
                                   job,
                                   dataset_id,
                                   Subdirectory,
                                   entered,
                                   RetrySucceeded)
    SELECT entry_id,
           job,
           dataset_id,
           subfolder,
           entered,
           false
    FROM cap.t_myemsl_uploads
    WHERE error_code = 0 AND
          verified = 0 AND
          entered < CURRENT_TIMESTAMP - make_interval(days => _staleUploadDays);

    If Not FOUND Then
        _message := 'Nothing to do';
        If _infoOnly Then
            RAISE INFO 'No stale uploads were found';
        End If;

        DROP TABLE Tmp_StaleUploads;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for uploads that were retried and the retry succeeded
    ---------------------------------------------------

    UPDATE Tmp_StaleUploads Target
    SET RetrySucceeded = true
    FROM cap.t_myemsl_uploads Uploads
    WHERE Target.dataset_id = Uploads.dataset_id AND
          Target.Subdirectory = Uploads.subfolder AND
          Uploads.verified > 0;

    If FOUND Then
        _foundRetrySuccessTasks := true;
    End If;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview tasks to update
        ---------------------------------------------------

        RAISE INFO ' ';

        _infoHead := format(_formatSpecifier,
                            'Age (days)',
                            'Retry Succeeded',
                            'Entry_id',
                            'Job',
                            'Dataset_id',
                            'New Files',
                            'Updated Files',
                            'Entered'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                            '----------',
                            '---------------',
                            '----------',
                            '----------',
                            '----------',
                            '----------',
                            '--------------',
                            '--------------------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _uploadInfo IN
            SELECT Stale.Entered,            -- This is used to compute the age of the upload, in days
                   Stale.RetrySucceeded,
                   Uploads.entry_id,
                   Uploads.job,
                   Uploads.dataset_id,
                   Uploads.file_count_new,
                   Uploads.file_count_updated
            FROM cap.V_MyEMSL_Uploads Uploads
                 INNER JOIN Tmp_StaleUploads Stale
                   ON Uploads.Entry_ID = Stale.Entry_ID
            ORDER BY RetrySucceeded Desc, Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                    round(extract(epoch FROM CURRENT_TIMESTAMP - _uploadInfo.Entered) / 86400),  -- Age (days)
                    CASE WHEN _uploadInfo.RetrySucceeded THEN 'Yes' ELSE 'No' END,
                    _uploadInfo.entry_id,
                    _uploadInfo.job,
                    _uploadInfo.dataset_id,
                    _uploadInfo.file_count_new,
                    _uploadInfo.file_count_updated,
                    timestamp_text(_uploadInfo.entered)
                );

            RAISE INFO '%', _infoData;

        END LOOP;
    Else

        ---------------------------------------------------
        -- Perform the update
        ---------------------------------------------------

        If _foundRetrySuccessTasks Then
            -- Silently update any where the retry succeeded
            --
            UPDATE cap.t_myemsl_uploads Uploads
            SET error_code = 101
            FROM Tmp_StaleUploads Stale
            WHERE Uploads.Entry_ID = Stale.Entry_ID AND
                  Stale.RetrySucceeded;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount > 0 Then
                _message := format('Set error_code to 101 for %s %s in t_myemsl_uploads',
                                    _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

                RAISE INFO '%', _message;
            End If;

            DELETE FROM Tmp_StaleUploads
            WHERE RetrySucceeded;
        End If;

        -- We keep seeing really old uploads that should already have a non-zero error code
        -- getting inserted into Tmp_StaleUploads and then being logged into cap.t_log_entries
        -- There should not be any records that are old, unverified, and have an error_code of zero

        -- Log details of the first five uploads that were entered over 1 year ago and yet are in Tmp_StaleUploads

        _entryID := 0;

        WHILE _iteration < _entryCountToLog
        LOOP

            SELECT Entry_ID
            INTO _entryID
            FROM Tmp_StaleUploads
            WHERE Entry_ID > _entryID And Entered < CURRENT_TIMESTAMP - Interval '365 days'
            ORDER BY Entry_ID
            LIMIT 1;

            If Not FOUND Then
                _iteration := _entryCountToLog + 1;
            Else

                SELECT Job,
                       SubFolder,
                       file_count_new As FileCountNew,
                       file_count_updated As FileCountUpdated,
                       Bytes,
                       Verified,
                       ingest_steps_completed As IngestStepsCompleted,
                       error_code As ErrorCode,
                       Entered
                INTO _uploadInfo
                FROM cap.t_myemsl_uploads
                WHERE entry_id = _entryID;

                _logMessage := format('Details of an old MyEMSL upload entry to be marked stale; ' ||
                                      'Entry ID: %s, Capture task job: %s, Subfolder: %s, ' ||
                                      'FileCountNew: %s, FileCountUpdated: %s, Bytes: %s, ' ||
                                      'Verified: %s, IngestStepsCompleted: %s, ErrorCode: %s, Entered: %s',
                                         _entryID,
                                         _uploadInfo.Job,
                                         Coalesce(_uploadInfo.SubFolder, 'Null'),
                                         _uploadInfo.FileCountNew,
                                         _uploadInfo.FileCountUpdated,
                                         _uploadInfo.Bytes,
                                         _uploadInfo.Verifed,
                                         Coalesce(_uploadInfo.IngestStepsCompleted::text, 'Null'),
                                         _uploadInfo.ErrorCode,
                                         timestamp_text(_uploadInfo.Entered));

                CALL public.post_log_entry ('Error', _logMessage, 'Find_Stale_MyEMSL_Uploads', 'cap');

                _iteration := _iteration + 1;

            End If;
        END LOOP;

        -- Update uploads where a successful retry does not exist
        --
        UPDATE cap.t_myemsl_uploads Uploads
        SET error_code = 101
        FROM Tmp_StaleUploads Stale
        WHERE Uploads.Entry_ID = Stale.Entry_ID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount = 1 Then
            SELECT Entry_ID, Job
            INTO _entryID, _job
            FROM Tmp_StaleUploads;

            -- MyEMSL upload task 1625978 for job 3773650 has been unverified for over 45 days; error_code set to 101
            _message := format('MyEMSL upload task %s for job %s has been', _entryID, _job);
        End If;

        If _updateCount > 1 Then

            SELECT string_agg(Entry_ID::text, ','),
                   string_agg(Job::text,      ',')
            INTO _entryIDList, _jobList
            FROM ( SELECT Entry_ID, Job
                  FROM Tmp_StaleUploads
                  ORDER BY Entry_ID
                  LIMIT 20) FilterQ;

            -- MyEMSL upload tasks 1633334,1633470,1633694 for capture task jobs 3789097,3789252,3789798 have been unverified for over 45 days; error_code set to 101
            _message := format('MyEMSL upload tasks %s for capture task jobs %s have been',_entryIDList, _jobList);
        End If;

        If _updateCount > 0 Then
            _message := format('%s unverified for over %s days; error_code set to 101', _message, _staleUploadDays);
            CALL public.post_log_entry ('Error', _message, 'Find_Stale_MyEMSL_Uploads', 'cap');

            RAISE INFO '%', _message;
        End If;

    End If;

    DROP TABLE Tmp_StaleUploads;
END
$$;


ALTER PROCEDURE cap.find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text) IS 'FindStaleMyEMSLUploads';

