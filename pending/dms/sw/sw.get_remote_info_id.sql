--
CREATE OR REPLACE FUNCTION sw.get_remote_info_id
(
    _remoteInfo text = '',
    _infoOnly boolean = false
)
RETURNS int
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resolves _remoteInfo to the ID in T_Remote_Info
**      Adds a new row to T_Remote_Info if new
**
**  Return values: RemoteInfoID, or 0 if _remoteInfo is empty
**
**  Arguments:
**    _infoOnly   If false, update T_Remote_Info if _remoteInfo is new; otherwise, shows a message if _remoteInfo is new
**
**  Auth:   mem
**  Date:   05/18/2017 mem - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _remoteInfoId int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _remoteInfo := Coalesce(_remoteInfo, '');
    _infoOnly := Coalesce(_infoOnly, false);

    If Coalesce(_remoteInfo, '') = '' Then
        RETURN 0;
    End If;

    ---------------------------------------------------
    -- Look for an existing remote info item
    ---------------------------------------------------

    SELECT remote_info_id
    INTO _remoteInfoID
    FROM sw.t_remote_info
    WHERE remote_info = _remoteInfo;

    If Not FOUND Then
        If _infoOnly Then
            RAISE INFO 'Remote info not found in sw.t_remote_info: %', _remoteInfo;
        Else
            ---------------------------------------------------
            -- Add a new entry to sw.t_remote_info
            -- Use a Merge statement to avoid the use of an explicit transaction
            ---------------------------------------------------

            MERGE INTO sw.t_remote_info AS target
            USING ( SELECT _remoteInfo AS Remote_Info
                  ) AS Source
            ON (target.remote_info = source.remote_info)
            WHEN NOT MATCHED THEN
                INSERT (remote_info, entered)
                VALUES (source.remote_info, CURRENT_TIMESTAMP);

            SELECT remote_info_id
            INTO _remoteInfoID
            FROM sw.t_remote_info
            WHERE remote_info = _remoteInfo;
        End If;
    Else
        If _infoOnly Then

            -- ToDo: Update this to use RAISE INFO

            SELECT 'Existing item found' As Status, *
            FROM sw.t_remote_info
            WHERE remote_info_id = _remoteInfoID
        End If;
    End If;

    RETURN _remoteInfoID
END
$$;

COMMENT ON PROCEDURE sw.get_remote_info_id IS 'GetRemoteInfoID';

