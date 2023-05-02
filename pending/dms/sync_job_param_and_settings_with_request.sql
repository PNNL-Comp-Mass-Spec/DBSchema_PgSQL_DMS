--
CREATE OR REPLACE PROCEDURE public.sync_job_param_and_settings_with_request
(
    _requestMinimum int = 0,
    _recentRequestDays int = 14,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the settings file name and parameter file name
**      for analysis job requests based on the settings file name
**      and parameter file name actually used
**
**      This helps keep the request and jobs in sync for bookkeeping purposes
**      Only updates job requests if all of the jobs associated with the
**      request used the same parameter file and settings file
**
**  Arguments:
**    _requestMinimum      Minimum request ID to examine (ignored if _recentRequestDays is positive)
**    _recentRequestDays   Process requests created within the most recent x days; 0 to use _requestMinimum
**
**  Auth:   mem
**  Date:   04/17/2014 mem - Initial version
**          07/29/2022 mem - No longer filter out null parameter file or settings file names since neither column allows null values
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _requestMinimum := Coalesce(_requestMinimum, 0);
    _recentRequestDays := Coalesce(_recentRequestDays, 14);
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode:= '';

    If _requestMinimum < 1 And _recentRequestDays < 1 Then
        _recentRequestDays := 14;
    End If;

    If _recentRequestDays > 0 Then
        SELECT MIN(request_id) INTO _requestMinimum
        FROM t_analysis_job_request
        WHERE created >= CURRENT_TIMESTAMP - make_interval(days => _recentRequestDays) AND
              request_id > 1;

        _requestMinimum := Coalesce(_requestMinimum, 2);
    End If;

    -- Make sure _requestMinimum is not 1=Default Request
    If _requestMinimum < 2 Then
        _requestMinimum := 2;
    End If;

    If _infoOnly Then
        Select _requestMinimum as MinimumRequestID;
    End If;

    -----------------------------------------------------------
    -- Create a temp table
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestIDs (
        RequestID int NOT NULL)

    CREATE UNIQUE INDEX IX_Tmp_RequestIDs ON Tmp_RequestIDs(RequestID);

    CREATE TEMP TABLE Tmp_Request_Params (
        RequestID int NOT NULL,
        ParamFileName text not null,
        SettingsFileName text not null)

    CREATE UNIQUE INDEX IX_Tmp_Request_Params ON Tmp_Request_Params(RequestID);

    -----------------------------------------------------------
    -- Find analysis jobs that came from a job request
    --   and for which all of the jobs used the same parameter file and settings file
    -- This is accomplished in two steps, with two temporary tables,
    --   since a single-step query was found to not scale well
    -----------------------------------------------------------
    --
    INSERT INTO Tmp_RequestIDs (RequestID)
    SELECT A.request_id
    FROM ( SELECT request_id,
                settings_file_name,
                param_file_name,
                COUNT(*) AS Jobs
            FROM t_analysis_job AJ
            WHERE request_id >= _requestMinimum
            GROUP BY request_id, settings_file_name, param_file_name
        ) A
        INNER JOIN
        ( SELECT request_id,
                COUNT(*) AS Jobs
            FROM t_analysis_job AJ
            WHERE request_id >= _requestMinimum
            GROUP BY request_id
        ) B
            ON A.request_id = B.request_id
    WHERE A.Jobs = B.Jobs
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------------------
    -- Cache the param file and settings file for the requests
    -----------------------------------------------------------
    --
    INSERT INTO Tmp_Request_Params (RequestID, ParamFileName, SettingsFileName)
    SELECT J.request_id,
           J.param_file_name,
           J.settings_file_name
    FROM t_analysis_job J
         INNER JOIN Tmp_RequestIDs FilterQ
           ON J.request_id = FilterQ.RequestID
    GROUP BY J.request_id, J.param_file_name, J.settings_file_name
    ORDER BY J.request_id
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then

        -----------------------------------------------------------
        -- Preview the requests that would be updated
        -----------------------------------------------------------
        --
        SELECT Target.request_id AS RequestID,
               Target.param_file_name AS ParamFileName,
               Case When Target.param_file_name <> R.ParamFileName Then R.ParamFileName Else '' End as ParamFileNameNew,
               Target.settings_file_name AS SettingsFileName,
               Case When Target.settings_file_name <> R.SettingsFileName Then R.SettingsFileName Else '' End as SettingsFileNameNew
        FROM t_analysis_job_request Target
             INNER JOIN Tmp_Request_Params R
               ON Target.request_id = R.RequestID
        WHERE Target.request_state_id > 1 AND
              (Target.param_file_name <> R.ParamFileName OR
               Target.settings_file_name <> R.SettingsFileName)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'All requests are up-to-date';
        Else
            _message := 'Need to update the parameter file name and/or settings file name for ' || _myRowCount::text || ' job requests, based on the actual jobs';
        End If;

        RAISE INFO '%', _message;
    Else

        -----------------------------------------------------------
        -- Update the requests
        -----------------------------------------------------------
        --
        UPDATE t_analysis_job_request
        SET param_file_name = R.ParamFileName,
            settings_file_name = R.SettingsFileName
        FROM t_analysis_job_request Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_analysis_job_request
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_analysis_job_request.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_Request_Params R
               ON Target.AJR_RequestID = R.RequestID
        WHERE Target.AJR_State > 1 AND
              (Target.AJR_parmFileName <> R.ParamFileName OR
               Target.AJR_settingsFileName <> R.SettingsFileName)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'All requests are up-to-date';
        Else
            _message := 'Updated the parameter file name and/or settings file name for ' || _myRowCount::text || ' job requests to match the actual jobs';

            Call post_log_entry ('Normal', _message, 'SyncJobParamAndSettingsWithRequest');
        End If;

    End If;

    DROP TABLE Tmp_RequestIDs;
    DROP TABLE Tmp_Request_Params;
END
$$;

COMMENT ON PROCEDURE public.sync_job_param_and_settings_with_request IS 'SyncJobParamAndSettingsWithRequest';
