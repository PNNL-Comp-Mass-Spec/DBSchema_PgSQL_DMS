--
-- Name: get_uri_path_id(text, boolean); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.get_uri_path_id(_uripath text, _infoonly boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for _uriPath in T_URI_Paths
**      Add a new row if missing (and _infoOnly is false)
**
**      Returns the ID of T_URI_Paths in T_URI_Paths
**      Will return 0 if _infoOnly is true and a match is not found
**
**  Auth:   mem
**  Date:   04/02/2012 mem - Initial version
**          06/27/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _uriPathID int;
BEGIN
    ------------------------------------------------
    -- Look for _uriPath in dpkg.t_uri_paths
    ------------------------------------------------

    SELECT uri_path_id
    INTO _uriPathID
    FROM dpkg.t_uri_paths
    WHERE uri_path = _uriPath
    ORDER BY uri_path_id
    LIMIT 1;

    If Not FOUND And Not _infoOnly Then
        ------------------------------------------------
        -- Match not found
        -- Add a new entry (use a Merge in case two separate calls are simultaneously made for the same _uriPath)
        ------------------------------------------------

        MERGE INTO dpkg.t_uri_paths AS t
        USING (SELECT _uriPath AS URI_Path
              ) AS s
        ON (t.uri_path = s.uri_path)
        WHEN NOT MATCHED THEN
            INSERT (uri_path)
            VALUES (s.URI_Path)
        ;

        -- Now that the merge is complete, a match should be found
        SELECT uri_path_id
        INTO _uriPathID
        FROM dpkg.t_uri_paths
        WHERE uri_path = _uriPath
        ORDER BY uri_path_id
        LIMIT 1;

    End If;

    RETURN Coalesce(_uriPathID, 0);
END
$$;


ALTER FUNCTION dpkg.get_uri_path_id(_uripath text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_uri_path_id(_uripath text, _infoonly boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.get_uri_path_id(_uripath text, _infoonly boolean) IS 'GetURIPathID';

