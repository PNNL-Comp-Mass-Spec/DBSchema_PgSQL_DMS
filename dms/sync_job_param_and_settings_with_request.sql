--
-- Name: sync_job_param_and_settings_with_request(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.sync_job_param_and_settings_with_request(IN _requestminimum integer DEFAULT 0, IN _recentrequestdays integer DEFAULT 14, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the settings file name and parameter file name for analysis job requests
**      based on the settings file name and parameter file name actually used
**
**      This helps keep the request and jobs in sync for bookkeeping purposes
**
**      Only updates job requests if all of the jobs associated with the request used the same parameter file and settings file
**
**  Arguments:
**    _requestMinimum       Minimum analysis job request ID to examine (ignored if _recentRequestDays is positive)
**    _recentRequestDays    Process requests created within the most recent x days; 0 to use _requestMinimum
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   04/17/2014 mem - Initial version
**          07/29/2022 mem - No longer filter out null parameter file or settings file names since neither column allows null values
**          02/25/2024 mem - If _recentRequestDays is non-zero and no requests were created within the given days, double the value and look again for job requests
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _requestMinimum    := Coalesce(_requestMinimum, 0);
    _recentRequestDays := Coalesce(_recentRequestDays, 14);
    _infoOnly          := Coalesce(_infoOnly, false);

    If _requestMinimum < 1 And _recentRequestDays < 1 Then
        _recentRequestDays := 14;
    End If;

    If _recentRequestDays > 0 Then
        _requestMinimum := null;

        WHILE _requestMinimum Is Null
        LOOP
            SELECT MIN(request_id)
            INTO _requestMinimum
            FROM t_analysis_job_request
            WHERE created >= CURRENT_TIMESTAMP - make_interval(days => _recentRequestDays) AND
                  request_id > 1;

            If Not _requestMinimum Is Null Then
                -- Break out of the while loop
                EXIT;
            End If;

            -- Did not find any job requests
            -- Double _recentRequestDays if it is less than 7305 (20 years)

            If _requestMinimum >= 7305 Then
                _requestMinimum := 2;
            Else
                _recentRequestDays := _recentRequestDays * 2;
            End If;
        END LOOP;

        _requestMinimum := Coalesce(_requestMinimum, 2);
    End If;

    -- Make sure _requestMinimum is not 1=Default Request
    If _requestMinimum < 2 Then
        _requestMinimum := 2;
    End If;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Minimum Request ID: %', _requestMinimum;
    End If;

    -----------------------------------------------------------
    -- Create a temp table
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestIDs (
        RequestID int NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_RequestIDs ON Tmp_RequestIDs(RequestID);

    CREATE TEMP TABLE Tmp_Request_Params (
        RequestID int NOT NULL,
        ParamFileName text NOT NULL,
        SettingsFileName text NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_Request_Params ON Tmp_Request_Params(RequestID);

    -----------------------------------------------------------
    -- Find analysis jobs that came from an analysis job request
    -- and for which all of the jobs used the same parameter file and settings file
    --
    -- This is accomplished in two steps, with two temporary tables,
    -- since a single-step query was found to not scale well
    -----------------------------------------------------------

    INSERT INTO Tmp_RequestIDs (RequestID)
    SELECT A.request_id
    FROM (SELECT request_id,
                 settings_file_name,
                 param_file_name,
                 COUNT(AJ.job) AS Jobs
          FROM t_analysis_job AJ
          WHERE request_id >= _requestMinimum
          GROUP BY request_id, settings_file_name, param_file_name
         ) A
         INNER JOIN
         (SELECT request_id,
                 COUNT(AJ.job) AS Jobs
          FROM t_analysis_job AJ
          WHERE request_id >= _requestMinimum
          GROUP BY request_id
         ) B
            ON A.request_id = B.request_id
    WHERE A.Jobs = B.Jobs;

    -----------------------------------------------------------
    -- Cache the param file and settings file for the requests
    -----------------------------------------------------------

    INSERT INTO Tmp_Request_Params (RequestID, ParamFileName, SettingsFileName)
    SELECT J.request_id,
           J.param_file_name,
           J.settings_file_name
    FROM t_analysis_job J
         INNER JOIN Tmp_RequestIDs FilterQ
           ON J.request_id = FilterQ.RequestID
    GROUP BY J.request_id, J.param_file_name, J.settings_file_name
    ORDER BY J.request_id;

    If _infoOnly Then

        -----------------------------------------------------------
        -- Preview the requests that would be updated
        -----------------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-100s %-100s %-60s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Request_ID',
                            'Param_File_Name',
                            'Param_File_Name_New',
                            'Settings_File_Name',
                            'Settings_File_Name_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------------------------------------------------------------------------------------------------',
                                     '----------------------------------------------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        _matchCount := 0;

        FOR _previewData IN
            SELECT Target.request_id AS Request_ID,
                   Target.param_file_name AS Param_File_Name,
                   CASE WHEN Target.param_file_name <> R.ParamFileName THEN R.ParamFileName ELSE '-- no change --' END AS Param_File_Name_New,
                   Target.settings_file_name AS Settings_File_Name,
                   CASE WHEN Target.settings_file_name <> R.SettingsFileName THEN R.SettingsFileName ELSE '-- no change --' END AS Settings_File_Name_New
            FROM t_analysis_job_request Target
                 INNER JOIN Tmp_Request_Params R
                   ON Target.request_id = R.RequestID
            WHERE Target.request_state_id > 1 AND
                  (Target.param_file_name <> R.ParamFileName OR
                   Target.settings_file_name <> R.SettingsFileName)
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Request_ID,
                                _previewData.Param_File_Name,
                                _previewData.Param_File_Name_New,
                                _previewData.Settings_File_Name,
                                _previewData.Settings_File_Name_New
                               );

            RAISE INFO '%', _infoData;

            _matchCount := _matchCount + 1;
        END LOOP;

        If _matchCount = 0 Then
            _message := 'All requests are up-to-date';
        Else
            _message := format('Need to update the parameter file name and/or settings file name for %s job %s, based on the actual jobs',
                                _matchCount, public.check_plural(_matchCount, 'request', 'requests'));
        End If;

        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_RequestIDs;
        DROP TABLE Tmp_Request_Params;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Update the requests
    -----------------------------------------------------------

    UPDATE t_analysis_job_request Target
    SET param_file_name = R.ParamFileName,
        settings_file_name = R.SettingsFileName
    FROM Tmp_Request_Params R
    WHERE Target.request_id = R.RequestID AND
          Target.request_state_id > 1 AND
          (Target.param_file_name <> R.ParamFileName OR
           Target.settings_file_name <> R.SettingsFileName);
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount = 0 Then
        _message := 'All requests are up-to-date';
    Else
        _message := format('Updated the parameter file name and/or settings file name for %s job %s to match the actual jobs',
                            _matchCount, public.check_plural(_matchCount, 'request', 'requests'));

        CALL post_log_entry ('Normal', _message, 'Sync_Job_Param_And_Settings_With_Request');
    End If;

    DROP TABLE Tmp_RequestIDs;
    DROP TABLE Tmp_Request_Params;
END
$$;


ALTER PROCEDURE public.sync_job_param_and_settings_with_request(IN _requestminimum integer, IN _recentrequestdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE sync_job_param_and_settings_with_request(IN _requestminimum integer, IN _recentrequestdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.sync_job_param_and_settings_with_request(IN _requestminimum integer, IN _recentrequestdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SyncJobParamAndSettingsWithRequest';

