--
CREATE OR REPLACE PROCEDURE public.update_bionet_host_status_from_list
(
    _hostNames text,
    _addMissingHosts boolean = false,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the Last_Online column in T_Bionet_Hosts
**      for the computers in _hostNames
**
**  Arguments:
**    _hostNames   Comma separated list of computer names.  Optionally include IP address with each host name using the format host_iP
**
**  Auth:   mem
**  Date:   12/03/2015 mem - Initial version
**          12/04/2015 mem - Now auto-removing ".bionet"
**                         - Add support for including IP addresses, for example ltq_orb_3_192.168.30.78
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _hostCount int := 0;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _hostNames := Coalesce(_hostNames, '');
    _addMissingHosts := Coalesce(_addMissingHosts, false);
    _infoOnly := Coalesce(_infoOnly, false);

    -----------------------------------------
    -- Create a temporary table
    -----------------------------------------

    CREATE TEMP TABLE Tmp_Hosts (
        Host text not null,        -- Could have Host and IP, encoded as Host_iP
        IP text null
    )

    CREATE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host);

    -----------------------------------------
    -- Parse the list of host names (or Host and IP combos)
    -----------------------------------------

    INSERT INTO Tmp_Hosts (Host)
    SELECT DISTINCT Value
    FROM public.parse_delimited_list(_hostNames, ',')
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _hostCount := _myRowCount;

    -- Split out IP address
    --
    UPDATE Tmp_Hosts
    SET Host = SubString(FilterQ.HostAndIP, 1, AtSignLoc - 1),
        IP = SubString(FilterQ.HostAndIP, AtSignLoc + 1, 16)
    FROM ( SELECT Host AS HostAndIP,
                  Position('@' InHost) AS AtSignLoc
           FROM Tmp_Hosts

           /********************************************************************************
           ** This UPDATE query includes the target table name in the FROM clause
           ** The WHERE clause needs to have a self join to the target table, for example:
           **   UPDATE Tmp_Hosts
           **   SET ...
           **   FROM source
           **   WHERE source.id = Tmp_Hosts.id;
           ********************************************************************************/

                                  ToDo: Fix this query

           WHERE Host SIMILAR TO '%@[0-9]%' ) FilterQ
         INNER JOIN Tmp_Hosts
           ON FilterQ.HostAndIP = Tmp_Hosts.Host
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Remove suffix .bionet if present
    --
    UPDATE Tmp_Hosts
    SET Host = Replace(Host, '.bionet', '')
    WHERE Host LIKE '%.bionet'
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        -----------------------------------------
        -- Preview the new info
        -----------------------------------------

        SELECT Src.Host,
               Src.IP,
               CASE
                   WHEN Target.Host IS NULL AND
                        Not _addMissingHosts THEN 'Host not found; will be skipped'
                   WHEN Target.Host IS NULL AND
                        _addMissingHosts THEN 'Host not found; will be added'
                   ELSE ''
               END AS Warning,
               Target.Last_Online,
               CASE
                   WHEN Target.Host IS NULL AND
                        Not _addMissingHosts THEN NULL
                   ELSE CURRENT_TIMESTAMP
               END AS New_Last_Online,
               Target.ip AS Last_IP
        FROM Tmp_Hosts Src
             LEFT OUTER JOIN t_bionet_hosts Target
               ON Target.host = Src.host
        ORDER BY Src.host
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else

        -----------------------------------------
        -- Update Last_Online for existing hosts
        -----------------------------------------

        UPDATE t_bionet_hosts
        SET last_online = CURRENT_TIMESTAMP,
            ip = Coalesce(Src.ip, Target.ip)
        FROM Tmp_Hosts Src
             INNER JOIN t_bionet_hosts Target
               ON Target.host = Src.host
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount < _hostCount And _addMissingHosts Then
            -- Add missing hosts

            INSERT INTO t_bionet_hosts( host,
                                        ip,
                                        entered,
                                        last_online )
            SELECT Src.host,
                   Src.ip,
                   CURRENT_TIMESTAMP,
                   CURRENT_TIMESTAMP
            FROM Tmp_Hosts Src
                 LEFT OUTER JOIN t_bionet_hosts Target
                   ON Target.host = Src.host
            WHERE Target.host IS NULL
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;

    End If;

    DROP TABLE Tmp_Hosts;
END
$$;

COMMENT ON PROCEDURE public.update_bionet_host_status_from_list IS 'UpdateBionetHostStatusFromList';
