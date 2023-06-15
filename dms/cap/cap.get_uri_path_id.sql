--
-- Name: get_uri_path_id(text, boolean); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_uri_path_id(_uripath text, _infoonly boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Looks for _uriPath in T_URI_Paths
**          Adds a new row if missing (and _infoOnly is false)
**
**          Returns the ID of T_URI_Paths in T_URI_Paths
**          Will return 1 if _infoOnly is true and a match is not found
**
**  Auth:   mem
**  Date:   04/02/2012 mem - Initial version
**          09/27/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _uri_PathID int;
BEGIN
    ------------------------------------------------
    -- Look for _uriPath in cap.t_uri_paths
    ------------------------------------------------

    SELECT uri_path_id
    INTO _uri_PathID
    FROM cap.t_uri_paths
    WHERE uri_path = _uriPath
    ORDER BY uri_path_id
    LIMIT 1;

    If Not FOUND Then
        ------------------------------------------------
        -- Match not found
        -- Add a new entry
        ------------------------------------------------

        If Not _infoOnly Then

            INSERT INTO cap.t_uri_paths (uri_path)
            VALUES (_uriPath)
            RETURNING uri_path_id
            INTO _uri_PathID;

        End If;

    End If;

    RETURN Coalesce(_uri_PathID, 1);
END
$$;


ALTER FUNCTION cap.get_uri_path_id(_uripath text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_uri_path_id(_uripath text, _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_uri_path_id(_uripath text, _infoonly boolean) IS 'GetURIPathID';

