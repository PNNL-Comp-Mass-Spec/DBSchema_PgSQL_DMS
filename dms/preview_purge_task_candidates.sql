--
-- Name: preview_purge_task_candidates(text, text, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.preview_purge_task_candidates(IN _storageservername text DEFAULT ''::text, IN _storagevol text DEFAULT ''::text, IN _datasetspershare integer DEFAULT 5, IN _previewsql boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Display the next _datasetsPerShare datasets that would be purged on the specified server,
**      or on a series of servers (if _storageServerName and/or _storageVol are blank)
**
**      Calls procedure request_purge_task() using _infoOnly = true
**
**  Arguments:
**    _storageServerName    Storage server to use, for example 'Proto-9'; if blank, returns candidates for all storage servers; when blank, _storageVol is ignored
**    _storageVol           Volume on storage server to use, for example 'G:\'; if blank, returns candidates for all drives on given server (or all servers if _storageServerName is blank)
**    _datasetsPerShare     Number of purge candidates to return for each share on each server
**    _previewSql           When true, preview SQL
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   12/30/2010 mem - Initial version
**          01/11/2011 mem - Renamed parameter _serverVol to _serverDisk when calling Request_Purge_Task
**          02/01/2011 mem - Now passing parameter _excludeStageMD5RequiredDatasets to Request_Purge_Task
**          06/07/2013 mem - Now auto-updating _storageServerName and _storageVol to match the format required by Request_Purge_Task
**          02/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _results refcursor;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------

    _storageServerName := Trim(Coalesce(_storageServerName, ''));
    _storageVol        := Trim(Coalesce(_storageVol, ''));
    _datasetsPerShare  := Coalesce(_datasetsPerShare, 5);
    _previewSql        := Coalesce(_previewSql, false);

    If _datasetsPerShare < 1 Then
        _datasetsPerShare := 1;
    End If;

    -- Auto change \\proto-6 to proto-6
    If _storageServerName Like '\\\\%' Then
        _storageServerName := Substring(_storageServerName, 3, char_length(_storageServerName));
    End If;

    -- Auto change proto-6\ to proto-6
    If _storageServerName Like '%\\' Then
        _storageServerName := Substring(_storageServerName, 1, char_length(_storageServerName) - 1);
    End If;

    -- Auto change drive F to F:\
    If _storageVol::citext SIMILAR TO '[A-Z]' Then
        _storageVol := format('%s:\', _storageVol);
    End If;

    -- Auto change drive F: to F:\
    If _storageVol::citext SIMILAR TO '[A-Z]:' Then
        _storageVol := format('%s\', _storageVol);
    End If;

    RAISE INFO '';
    RAISE INFO 'Server: %', _storageServerName;
    RAISE INFO 'Volume: %', _storageVol;

    --------------------------------------------------
    -- Call Request_Purge_Task to obtain the data
    --------------------------------------------------

    CALL public.request_purge_task (
                _storageServerName               => _storageServerName,
                _serverDisk                      => _storageVol,
                _excludeStageMD5RequiredDatasets => false,
                _results                         => _results,       -- Output
                _message                         => _message,       -- Output
                _returnCode                      => _returnCode,    -- Output
                _infoOnly                        => true,
                _previewCount                    => _datasetsPerShare,
                _previewSql                      => _previewSql,
                _showDebug                      => false
            );
END
$$;


ALTER PROCEDURE public.preview_purge_task_candidates(IN _storageservername text, IN _storagevol text, IN _datasetspershare integer, IN _previewsql boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE preview_purge_task_candidates(IN _storageservername text, IN _storagevol text, IN _datasetspershare integer, IN _previewsql boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.preview_purge_task_candidates(IN _storageservername text, IN _storagevol text, IN _datasetspershare integer, IN _previewsql boolean, INOUT _message text, INOUT _returncode text) IS 'PreviewPurgeTaskCandidates';

