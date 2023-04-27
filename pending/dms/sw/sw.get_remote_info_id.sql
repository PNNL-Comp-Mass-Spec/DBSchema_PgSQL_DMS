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
    _myRowCount int := 0;
    _remoteInfoId int;
BEGIN
    _remoteInfo := Coalesce(_remoteInfo, '');
    _infoOnly := Coalesce(_infoOnly, false);

    If Coalesce(_remoteInfo, '') = '' Then
        Return 0;
    End If;

    ---------------------------------------------------
    -- Look for an existing remote info item
    ---------------------------------------------------

    SELECT remote_info_id
    INTO _remoteInfoID
    FROM sw.t_remote_info
    WHERE remote_info = _remoteInfo
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        If _infoOnly Then
            SELECT 'Remote info not found in sw.t_remote_info' As Status, Null As Remote_Info_ID, _remoteInfo As Remote_Info
        Else
            ---------------------------------------------------
            -- Add a new entry to sw.t_remote_info
            -- Use a Merge statement to avoid the use of an explicit transaction
            ---------------------------------------------------
            --
            MERGE INTO sw.t_remote_info AS target
            USING ( SELECT _remoteInfo AS Remote_Info
                  ) AS Source
            ON (target.remote_info = source.remote_info)
            WHEN NOT MATCHED THEN
                INSERT (remote_info, entered)
                VALUES (source.remote_info, CURRENT_TIMESTAMP);
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            SELECT remote_info_id
            INTO _remoteInfoID
            FROM sw.t_remote_info
            WHERE remote_info = _remoteInfo;
        End If;
    Else
        If _infoOnly Then
            SELECT 'Existing item found' As Status, *
            FROM sw.t_remote_info
            WHERE remote_info_id = _remoteInfoID
        End If;
    End If;

    RETURN _remoteInfoID
END
$$;

COMMENT ON PROCEDURE sw.get_remote_info_id IS 'GetRemoteInfoID';

