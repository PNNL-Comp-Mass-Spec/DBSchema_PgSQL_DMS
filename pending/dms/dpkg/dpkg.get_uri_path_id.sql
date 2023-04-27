--
-- ToDo: convert this to a function that returns an integer
--
CREATE OR REPLACE PROCEDURE dpkg.get_uri_path_id
(
    _uriPath text,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Looks for _uriPath in T_URI_Paths
**          Adds a new row if missing (and _infoOnly is false)
**
**          Returns the ID of T_URI_Paths in T_URI_Paths
**          Will return 0 if _infoOnly is true and a match is not found
**
**  Auth:   mem
**  Date:   04/02/2012 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _uriPathID int;
BEGIN
    ------------------------------------------------
    -- Look for _uriPath in dpkg.t_uri_paths
    ------------------------------------------------
    --
    _uriPathID := 0;

    SELECT uri_path_id INTO _uriPathID
    FROM dpkg.t_uri_paths
    WHERE uri_path = _uriPath
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Or _uriPathID = 0 Then
        ------------------------------------------------
        -- Match not found
        -- Add a new entry (use a Merge in case two separate calls are simultaneously made for the same _uriPath)
        ------------------------------------------------

        If _infoOnly = false Then

            MERGE dpkg.t_uri_paths AS Target
            USING (
                    SELECT _uriPath
                   ) AS Source (URI_Path)
                ON Source.uri_path = Target.uri_path
            WHEN NOT MATCHED BY TARGET THEN
                INSERT ( uri_path )
                VALUES  ( Source.uri_path )
            ;

            -- Now that the merge is complete a match should be found
            SELECT uri_path_id INTO _uriPathID
            FROM dpkg.t_uri_paths
            WHERE uri_path = _uriPath
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;

    End If;

    return _uriPathID

END
$$;

COMMENT ON PROCEDURE dpkg.get_uri_path_id IS 'GetURIPathID';
