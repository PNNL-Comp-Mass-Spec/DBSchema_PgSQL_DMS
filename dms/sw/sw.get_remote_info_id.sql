--
-- Name: get_remote_info_id(text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_remote_info_id(_remoteinfo text DEFAULT ''::text, _infoonly boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resolve _remoteInfo to the ID in sw.t_remote_info
**      Add a new row to sw.t_remote_info if new
**
**  Returns:
**      RemoteInfoID, or 0 if _remoteInfo is empty
**
**  Arguments:
**    _remoteInfo   Remote info description
**    _infoOnly     If false, update sw.t_remote_info if _remoteInfo is new; otherwise, show a message if _remoteInfo is new
**
**  Auth:   mem
**  Date:   05/18/2017 mem - Initial release
**          08/08/2023 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
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
    _remoteInfo := Trim(Coalesce(_remoteInfo, ''));
    _infoOnly  := Coalesce(_infoOnly, false);

    If Coalesce(_remoteInfo, '') = '' Then
        RETURN 0;
    End If;

    ---------------------------------------------------
    -- Look for an existing remote info item
    ---------------------------------------------------

    SELECT remote_info_id
    INTO _remoteInfoID
    FROM sw.t_remote_info
    WHERE remote_info = _remoteInfo::citext;

    If Not FOUND Then
        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Remote info not found in sw.t_remote_info:';
            RAISE INFO '%', _remoteInfo;
        Else
            ---------------------------------------------------
            -- Add a new entry to sw.t_remote_info
            -- Use a Merge statement to avoid the use of an explicit transaction
            ---------------------------------------------------

            MERGE INTO sw.t_remote_info AS target
            USING (SELECT _remoteInfo AS Remote_Info
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

        RETURN Coalesce(_remoteInfoID, 0);
    End If;

    If Not _infoOnly Then
        RETURN Coalesce(_remoteInfoID, 0);
    End If;

    RAISE INFO '';

    _formatSpecifier := '%-20s %-14s %-15s %-20s %-20s %-21s %-250s';

    _infoHead := format(_formatSpecifier,
                        'Status',
                        'Remote_Info_ID',
                        'Most_Recent_Job',
                        'Last_Used',
                        'Entered',
                        'Max_Running_Job_Steps',
                        'Remote_Info'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '--------------------',
                                 '--------------',
                                 '---------------',
                                 '--------------------',
                                 '--------------------',
                                 '---------------------',
                                 '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT 'Existing item found' AS Status,
               Remote_Info_ID,
               Most_Recent_Job,
               public.timestamp_text(Last_Used) AS Last_Used,
               public.timestamp_text(Entered) AS Entered,
               Max_Running_Job_Steps,
               Remote_Info
        FROM sw.t_remote_info
        WHERE remote_info_id = _remoteInfoID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Status,
                            _previewData.Remote_Info_ID,
                            _previewData.Most_Recent_Job,
                            _previewData.Last_Used,
                            _previewData.Entered,
                            _previewData.Max_Running_Job_Steps,
                            _previewData.Remote_Info
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    RETURN Coalesce(_remoteInfoID, 0);
END
$$;


ALTER FUNCTION sw.get_remote_info_id(_remoteinfo text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_remote_info_id(_remoteinfo text, _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_remote_info_id(_remoteinfo text, _infoonly boolean) IS 'GetRemoteInfoID';

