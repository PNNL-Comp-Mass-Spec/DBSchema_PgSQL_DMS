--
CREATE OR REPLACE PROCEDURE public.preview_purge_task_candidates
(
    _storageServerName text = '',
    _storageVol text = '',
    _datasetsPerShare int = 5,
    _previewSql boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the next _datasetsPerShare datasets that would be purged on the specified server,
**      or on a series of servers (if _storageServerName and/or _storageVol are blank)
**
**  Arguments:
**    _storageServerName   Storage server to use, for example 'proto-9'; if blank, returns candidates for all storage servers; when blank, _storageVol is ignored
**    _storageVol          Volume on storage server to use, for example 'g:\'; if blank, returns candidates for all drives on given server (or all servers if _storageServerName is blank)
**    _datasetsPerShare    Number of purge candidates to return for each share on each server
**
**  Auth:   mem
**  Date:   12/30/2010 mem - Initial version
**          01/11/2011 mem - Renamed parameter _serverVol to _serverDisk when calling Request_Purge_Task
**          02/01/2011 mem - Now passing parameter _excludeStageMD5RequiredDatasets to Request_Purge_Task
**          06/07/2013 mem - Now auto-updating _storageServerName and _storageVol to match the format required by Request_Purge_Task
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------

    _storageServerName := Coalesce(_storageServerName, '');
    _storageVol := Coalesce(_storageVol, '');
    _datasetsPerShare := Coalesce(_datasetsPerShare, 5);
    _previewSql := Coalesce(_previewSql, false);

    If _datasetsPerShare < 1 Then
        _datasetsPerShare := 1;
    End If;

    -- Auto change \\proto-6 to proto-6
    If _storageServerName Like '\\%' Then
        _storageServerName := Substring(_storageServerName, 3, 50);
    End If;

    -- Auto change proto-6\ to proto-6
    If _storageServerName Like '%\' Then
        _storageServerName := Substring(_storageServerName, 1, char_length(_storageServerName)-1);
    End If;

    -- Auto change drive F to F:\
    If _storageVol SIMILAR TO '[A-Z]' Then
        _storageVol := format('%s:\', _storageVol);
    End If;

    -- Auto change drive F: to F:\
    If _storageVol SIMILAR TO '[a-z]:' Then
        _storageVol := format('%s\', _storageVol);
    End If;

    RAISE INFO 'Server: %', _storageServerName;
    RAISE INFO 'Volume: %', _storageVol;

    --------------------------------------------------
    -- Call Request_Purge_Task to obtain the data
    --------------------------------------------------

    CALL request_purge_task (
                        _storageServerName => _storageServerName,
                        _serverDisk => _storageVol,
                        _excludeStageMD5RequiredDatasets => false,
                        _message => _message,                   -- Output
                        _returnCode => _returnCode,             -- Output
                        _infoOnly => true,
                        _previewCount => _datasetsPerShare
                        _previewSql => _previewSql);

END
$$;

COMMENT ON PROCEDURE public.preview_purge_task_candidates IS 'PreviewPurgeTaskCandidates';
