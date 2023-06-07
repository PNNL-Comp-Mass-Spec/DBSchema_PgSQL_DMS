--
CREATE OR REPLACE PROCEDURE dpkg.find_stale_myemsl_uploads
(
    _staleUploadDays int = 45,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for unverified entries added to T_MyEMSL_Uploads over 45 ago (customize with _staleUploadDays)
**      For any that are found, sets the ErrorCode to 101 and posts an entry to T_Log_Entries
**
**  Auth:   mem
**  Date:   05/20/2019 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _entryID Int;
    _dataPackageID Int;
    _entryIDList text;
    _dataPackageList text;

 	_formatSpecifier text;
	_infoHead text;
	_infoHeadSeparator text;
    _uploadInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _staleUploadDays := Coalesce(_staleUploadDays, 45);
    _infoOnly := Coalesce(_infoOnly, false);

    If _staleUploadDays < 20 Then
        -- Require _staleUploadDays to be at least 20
        _staleUploadDays := 14;
    End If;

    ---------------------------------------------------
    -- Find and process stale uploads
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_StaleUploads (
        Entry_ID Int Not Null,
        Data_Package_ID Int Not Null,
        Entered timestamp
    )

    INSERT INTO Tmp_StaleUploads( entry_id,
                                   data_pkg_id,
                                   entered)
    SELECT entry_id,
           data_pkg_id,
           entered
    FROM dpkg.t_myemsl_uploads
    WHERE error_code = 0 AND
          verified = 0 AND
          entered < DateAdd(DAY, - _staleUploadDays, CURRENT_TIMESTAMP);

    If Not Exists (SELECT * FROM Tmp_StaleUploads) Then
        _message := 'Nothing to do';
        If _infoOnly Then
            RAISE INFO 'No stale uploads were found';
        End If;

        DROP TABLE Tmp_StaleUploads;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If _infoOnly Then

        _formatSpecifier := '%-20s %-10s %-10s %-10s %-80s %-30s %-60s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Message',
                            'Entry_ID',
                            'Job',
                            'Dataset_ID',
                            'Dataset',
                            'Subfolder',
                            'Status_uri',
                            'Entered'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                    '--------------------',
                                    '----------',
                                    '----------',
                                    '----------',
                                    '--------------------------------------------------------------------------------',
                                    '------------------------------',
                                    '------------------------------------------------------------',
                                    '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _uploadInfo IN
            SELECT format('Stale: %s days old', Round(extract(epoch FROM CURRENT_TIMESTAMP - Stale.Entered) / 86400)) As Message,
                   Uploads.entry_id,
                   Uploads.job,
                   Uploads.dataset_id,
                   Uploads.dataset,
                   Uploads.subfolder,
                   Uploads.status_uri,
                   Uploads.entered
            FROM V_MyEMSL_Uploads Uploads
                 INNER JOIN Tmp_StaleUploads Stale
                   ON Uploads.Entry_ID = Stale.Entry_ID
            ORDER BY Entry_ID
        LOOP

            RAISE INFO '%', format(_formatSpecifier,
                                   _uploadInfo.Message,
                                   _uploadInfo.Entry_ID,
                                   _uploadInfo.Job,
                                   _uploadInfo.Dataset_ID,
                                   _uploadInfo.Dataset,
                                   _uploadInfo.Subfolder,
                                   _uploadInfo.Status_uri,
                                   timestamp_text(_uploadInfo.Entered));
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
               Data_Package_ID
        INTO _entryID, _dataPackageID
        FROM Tmp_StaleUploads

        -- MyEMSL upload task 3944 for data package 2967 has been unverified for over 45 days; ErrorCode set to 101
        _message := format('MyEMSL upload task %s for data package %s has been', _entryID, _dataPackageID);
    Else
        SELECT string_agg(Entry_ID::text, ',' ORDER BY Entry_ID),
               string_agg(Data_Package_ID::text, ',' ORDER BY Data_Package_ID),
        INTO _entryIDList, _dataPackageList
        FROM Tmp_StaleUploads

        -- MyEMSL upload tasks 3944,4119,4120 for data packages 2967,2895,2896 have been unverified for over 45 days; ErrorCode set to 101
        _message := format('MyEMSL upload tasks %s for data packages %s have been', _entryIDList, _dataPackageList);
    End If;

    _message := format('%s unverified for over %s days; ErrorCode set to 101', _message, _staleUploadDays);

    CALL public.post_log_entry ('Error', _message, 'Find_Stale_MyEMSL_Uploads', 'dpkg');

    RAISE INFO '%', _message;

    DROP TABLE Tmp_StaleUploads;
END
$$;

COMMENT ON PROCEDURE dpkg.find_stale_myemsl_uploads IS 'FindStaleMyEMSLUploads';
