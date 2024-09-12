--
-- Name: find_stale_myemsl_uploads(integer, boolean, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.find_stale_myemsl_uploads(IN _staleuploaddays integer DEFAULT 45, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for unverified entries added to dpkg.t_myemsl_uploads over 45 days ago (customize with _staleUploadDays)
**      For any that are found, sets the ErrorCode to 101 and posts an entry to dpkg.T_Log_Entries
**
**  Arguments:
**    _staleUploadDays      Stale upload threshold, in days
**    _infoOnly             When true, show the stale uploads
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   05/20/2019 mem - Initial version
**          08/15/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/10/2024 mem - Set _logErrorsToPublicLogTable to false when calling post_log_entry
**
*****************************************************/
DECLARE
    _updateCount int;
    _entryID int;
    _dataPackageID int;
    _entryIDList text;
    _dataPackageList text;

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

    _staleUploadDays := Coalesce(_staleUploadDays, 45);
    _infoOnly        := Coalesce(_infoOnly, false);

    If _staleUploadDays < 20 Then
        -- Require _staleUploadDays to be at least 20
        _staleUploadDays := 14;
    End If;

    ---------------------------------------------------
    -- Find and process stale uploads
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_StaleUploads (
        Entry_ID int NOT NULL,
        Data_Pkg_ID int NOT NULL,
        Entered timestamp
    );

    INSERT INTO Tmp_StaleUploads (
        entry_id,
        data_pkg_id,
        entered
    )
    SELECT entry_id,
           data_pkg_id,
           entered
    FROM dpkg.t_myemsl_uploads
    WHERE error_code = 0 AND
          verified = 0 AND
          entered < CURRENT_TIMESTAMP + make_interval(days => -(_staleUploadDays));

    If Not Exists (SELECT * FROM Tmp_StaleUploads) Then
        _message := 'Nothing to do';

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'No stale uploads were found';
        End If;

        DROP TABLE Tmp_StaleUploads;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-10s %-11s %-70s %-60s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Message',
                            'Entry_id',
                            'Data_Pkg_ID',
                            'Subfolder',
                            'Status_URI',
                            'Entered'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '----------',
                                     '-----------',
                                     '----------------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT format('Stale: %s days old', Round(Extract(epoch from CURRENT_TIMESTAMP - Stale.Entered) / 86400)) AS Message,
                   Uploads.Entry_id,
                   Uploads.Data_Pkg_ID,
                   Uploads.Subfolder,
                   Uploads.Status_uri,
                   Uploads.Entered
            FROM dpkg.V_MyEMSL_Uploads Uploads
                 INNER JOIN Tmp_StaleUploads Stale
                   ON Uploads.Entry_ID = Stale.Entry_ID
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Message,
                                _previewData.Entry_ID,
                                _previewData.Data_Pkg_ID,
                                _previewData.Subfolder,
                                _previewData.Status_uri,
                                public.timestamp_text(_previewData.Entered)
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_StaleUploads;
        RETURN;
    End If;

    UPDATE dpkg.t_myemsl_uploads Uploads
    SET error_code = 101
    FROM Tmp_StaleUploads Stale
    WHERE Uploads.Entry_ID = Stale.Entry_ID;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount = 1 Then
        SELECT Entry_ID,
               Data_Pkg_ID
        INTO _entryID, _dataPackageID
        FROM Tmp_StaleUploads;

        _message := format('MyEMSL upload task %s for data package %s has been', _entryID, _dataPackageID);
    Else
        SELECT string_agg(Entry_ID::text, ',' ORDER BY Entry_ID),
               string_agg(Data_Pkg_ID::text, ',' ORDER BY Data_Pkg_ID)
        INTO _entryIDList, _dataPackageList
        FROM Tmp_StaleUploads;

        _message := format('MyEMSL upload tasks %s for data packages %s have been', _entryIDList, _dataPackageList);
    End If;

    -- Example values for _message:
    --   MyEMSL upload task 3944 for data package 2967 has been unverified for over 45 days; ErrorCode set to 101
    --   MyEMSL upload tasks 3944,4119,4120 for data packages 2967,2895,2896 have been unverified for over 45 days; ErrorCode set to 101

    _message := format('%s unverified for over %s days; ErrorCode set to 101', _message, _staleUploadDays);

    CALL public.post_log_entry ('Error', _message, 'Find_Stale_MyEMSL_Uploads', 'dpkg', _logErrorsToPublicLogTable => false);

    RAISE INFO '';
    RAISE INFO '%', _message;

    DROP TABLE Tmp_StaleUploads;
END
$$;


ALTER PROCEDURE dpkg.find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.find_stale_myemsl_uploads(IN _staleuploaddays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'FindStaleMyEMSLUploads';

