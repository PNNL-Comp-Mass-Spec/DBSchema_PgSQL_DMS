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
    _myRowCount int := 0;
    _entryID Int;
    _dataPackageID Int;
    _entryIDList text;
    _dataPackageList text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _staleUploadDays := Coalesce(_staleUploadDays, 45);
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode:= '';

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
          entered < DateAdd(DAY, - _staleUploadDays, CURRENT_TIMESTAMP)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If Not Exists (SELECT * FROM Tmp_StaleUploads) Then
        _message := 'Nothing to do';
        If _infoOnly Then
            Select 'No stale uploads were found' As Message
        End If;
        Return;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    If _infoOnly Then
        SELECT 'Stale: ' || Cast(DateDiff(Day, Stale.Entered, CURRENT_TIMESTAMP) As text) || ' days old' As Message,
               Uploads.*
        FROM V_MyEMSL_Uploads Uploads
             INNER JOIN Tmp_StaleUploads Stale
               ON Uploads.Entry_ID = Stale.Entry_ID
        ORDER BY Entry_ID
    Else
        Begin Tran

        UPDATE dpkg.t_myemsl_uploads
        SET error_code = 101
        FROM dpkg.t_myemsl_uploads Uploads

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE dpkg.t_myemsl_uploads
        **   SET ...
        **   FROM source
        **   WHERE source.id = dpkg.t_myemsl_uploads.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_StaleUploads Stale
               ON Uploads.Entry_ID = Stale.Entry_ID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 1 Then
            SELECT Entry_ID, INTO _entryID
                   _dataPackageID = Data_Package_ID
            FROM Tmp_StaleUploads

            -- MyEMSL upload task 3944 for data package 2967 has been unverified for over 45 days; ErrorCode set to 101
            _message := format('MyEMSL upload task %s for data package %s has been', _entryID, _dataPackageID);
        Else
            _entryIDList := '';
            _dataPackageList := '';

            SELECT string_agg(Entry_ID::text, ',' ORDER BY Entry_ID),
                   string_agg(Data_Package_ID::text, ',' ORDER BY Data_Package_ID),
            INTO _entryIDList, _dataPackageList
            FROM Tmp_StaleUploads

            -- MyEMSL upload tasks 3944,4119,4120 for data packages 2967,2895,2896 have been unverified for over 45 days; ErrorCode set to 101
            _message := format('MyEMSL upload tasks %s for data packages %s have been', _entryIDList, _dataPackageList);
        End If;

        _message := format('%s unverified for over %s days; ErrorCode set to 101', _message, _staleUploadDays);

        Call post_log_entry 'Error', _message, 'FindStaleMyEMSLUploads'

        Commit

        RAISE INFO '%', _message;

    End If;

    If _myError <> 0 Then
        If _message = '' Then
            _message := 'Error in FindStaleMyEMSLUploads';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        Call post_log_entry 'Error', _message, 'FindStaleMyEMSLUploads'
    End If;

    Return _myError

    DROP TABLE Tmp_StaleUploads
END
$$;

COMMENT ON PROCEDURE dpkg.find_stale_myemsl_uploads IS 'FindStaleMyEMSLUploads';
