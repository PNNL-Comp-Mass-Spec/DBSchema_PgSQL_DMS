--
-- Name: update_bto_usage_proc(boolean, text, text); Type: PROCEDURE; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE ont.update_bto_usage_proc(IN _infoonly boolean, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls function ont.update_bto_usage() to update the usage columns in ont.t_cv_bto
**
**      Used by timetable task "Update tissue usage"
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   03/25/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _updateCount int;
    _countWithUsageAllTime int;
    _countWithUsageLast12Months int;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_UpdateResults (
        tissue_id citext,
        usage_all_time int,
        usage_last_12_months int
    );

    INSERT INTO Tmp_UpdateResults (
        tissue_id,
        usage_all_time,
        usage_last_12_months
    )
    SELECT tissue_id, usage_all_time, usage_last_12_months
    FROM ont.update_bto_usage (_infoOnly => _infoOnly);

    If Not FOUND Then
        _message := 'Function ont.update_bto_usage() did not return any results';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
    Else
        If Exists (SELECT tissue_id
                   FROM Tmp_UpdateResults
                   WHERE tissue_id = 'Usage stats are already up-to-date')
        Then
            _message := 'Usage stats are already up-to-date';
        Else
            SELECT COUNT(tissue_id) AS Update_Count,
                   SUM(CASE WHEN usage_all_time > 0 THEN 1 ELSE 0 END) AS Tissue_Count_With_Usage,
                   SUM(CASE WHEN usage_last_12_months > 0 THEN 1 ELSE 0 END) AS Tissue_Count_With_Usage_Last_12_Months
            INTO _updateCount, _countWithUsageAllTime, _countWithUsageLast12Months
            FROM Tmp_UpdateResults
            LIMIT 1;

            _message := format('Updated %s %s; %s %s referenced by DMS experiments; %s %s used in the last 12 months',
                               _updateCount,
                               public.check_plural(_updateCount, 'tissue ID', 'tissue IDs'),
                               _countWithUsageAllTime,
                               public.check_plural(_countWithUsageAllTime, 'is', 'are'),
                               _countWithUsageLast12Months,
                               public.check_plural(_countWithUsageLast12Months, 'has been', 'have been')
                              );
        End If;

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_UpdateResults;
    RETURN;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _callingProcLocation => '', _logError => true);

    If Coalesce(_returnCode, '') = '' Then
        _returnCode := _sqlState;
    End If;

    DROP TABLE IF EXISTS Tmp_UpdateResults;
END;
$$;


ALTER PROCEDURE ont.update_bto_usage_proc(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

