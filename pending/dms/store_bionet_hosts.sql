--
CREATE OR REPLACE PROCEDURE public.store_bionet_hosts
(
    _hostList text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Updates the entries in T_Bionet_Hosts
**
**  Export the list of computers from DNS on Gigasax
**  by right clicking Bionet under "Forward Lookup Zones"
**  and choosing "Export list ..."
**
**  File format (tab-separated)
**
**     Name    Type    Data
**     (same as parent folder)    Host (A)    192.168.30.0
**     (same as parent folder)    Start of Authority (SOA)    [1102], gigasax.bionet.,
**     (same as parent folder)    Name Server (NS)    gigasax.bionet.
**     12t_agilent    Host (A)    192.168.30.61
**     12tfticr64     Host (A)    192.168.30.54
**     15t_fticr_2    Host (A)    192.168.30.80
**     15tfticr64     Host (A)    192.168.30.62
**     21tfticr       Host (A)    192.168.30.60
**     21tvpro        Host (A)    192.168.30.60
**
**  Auth:   mem
**  Date:   12/02/2015 mem - Initial version
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to Parse_Delimited_ListOrdered
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _columnCount int := 0;
    _lineDelimiter text;
    _tabDelimiter text;
    _entryID int := 0;
    _entryIDEnd int := 0;
    _charIndex int;
    _colCount int;
    _row text;
    _hostName citext;
    _hostType citext;
    _hostData text;
    _instruments text;
    _isAlias boolean;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _hostList := Coalesce(_hostList, '');
    _infoOnly := Coalesce(_infoOnly, false);

    If _hostList = '' Then
        _message := '_hostList is empty; unable to continue';
        _returnCode := 'U5201'
        RETURN;
    End If;

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_HostData (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Value text null
    );

    CREATE UNIQUE INDEX IX_Tmp_Hosts_EntryID ON Tmp_HostData (EntryID);

    CREATE TEMP TABLE Tmp_Hosts (
        Host text not null,
        NameOrIP text not null,
        IsAlias boolean not null,
        Instruments text null
    );

    CREATE UNIQUE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host);

    CREATE TEMP TABLE Tmp_DataColumns (
        EntryID int not null,
        Value text null
    );

    CREATE UNIQUE INDEX IX_Tmp_DataColumns_EntryID ON Tmp_DataColumns (EntryID);

    -----------------------------------------
    -- Split _hostList on carriage returns
    -- Store the data in Tmp_Hosts
    -----------------------------------------

    If Position(chr(10) In _hostList) > 0 Then
        _lineDelimiter := chr(10);
    Else
        _lineDelimiter := chr(13);
    End If;

    INSERT INTO Tmp_HostData (Value)
    SELECT Item
    FROM public.parse_delimited_list ( _hostList, _lineDelimiter )

    If Not Exists (SELECT * FROM Tmp_HostData) Then
        _message := 'Nothing returned when splitting the Host List on CR or LF';
        _returnCode := 'U5202'

        DROP TABLE Tmp_HostData;
        DROP TABLE Tmp_Hosts;
        DROP TABLE Tmp_DataColumns;
        RETURN;
    End If;

    SELECT MAX(EntryID)
    INTO _entryIDEnd
    FROM Tmp_HostData;

    -----------------------------------------
    -- Parse the host list
    -----------------------------------------

    -- Set the delimiter to a tab character
    _tabDelimiter := chr(9);

    FOR  _row IN
        SELECT Value
        FROM Tmp_HostData
        ORDER BY EntryID
    LOOP

        -- _row should now be empty, or contain something like the following (tab-separated values):
        -- 12tfticr64    Host (A)    192.168.30.54
        --   or
        -- agilent_qtof_02    Alias (CNAME)    agqtof02.

        _row := Replace (_row, chr(10), '');
        _row := Replace (_row, chr(13), '');
        _row := Trim(Coalesce(_row, ''));

        If Coalesce(_row, '') = '' Then
            CONTINUE;
        End If;

        -- Split the row on tabs to find HostName, HostType, and HostData
        TRUNCATE TABLE Tmp_DataColumns;

        INSERT INTO Tmp_DataColumns (EntryID, Value)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_row, _tabDelimiter, 0)
        --
        GET DIAGNOSTICS _columnCount = ROW_COUNT;

        If _columnCount < 3 Then
            RAISE INFO 'Skipping row since less than 3 columns: %', _row;
            CONTINUE;
        End If;

        _instruments := '';
        _isAlias := false;

        SELECT Value
        INTO _hostName
        FROM Tmp_DataColumns
        WHERE EntryID = 1;

        SELECT Value
        INTO _hostType
        FROM Tmp_DataColumns
        WHERE EntryID = 2;

        SELECT Value
        INTO _hostData
        FROM Tmp_DataColumns
        WHERE EntryID = 3;

        If Coalesce(_hostName, '') = '' Or Coalesce(_hostType, '') = '' Or Coalesce(_hostData, '') = '' Then
            RAISE INFO 'Skipping row since 1 or more columns are blank: %', _row;
            CONTINUE;
        End If;

        If _hostName <> '(same As parent folder)' And Not (_hostName = 'Name' And _hostType = 'Type') Then
            If _hostType Like 'Alias%' Then
                _isAlias := true;

                If _hostData Like '%.' Then
                    _hostData := SubString(_hostData, 1, char_length(_hostData) - 1);
                End If;
            End If;

            -- Look for instruments that have an inbox on this host
            --
            SELECT string_agg(Inst.instrument, ', ' ORDER BY Inst.instrument)
            INTO _instruments
            FROM t_storage_path SPath
                 INNER JOIN t_instrument_name Inst
                   ON SPath.storage_path_id = Inst.source_path_id
            WHERE SPath.machine_name = _hostName OR SPath.machine_name = format('%s.bionet', _hostName) AND
                  SPath.storage_path_function LIKE '%inbox%';

            INSERT INTO Tmp_Hosts (Host, NameOrIP, IsAlias, Instruments)
            VALUES (_hostName, _hostData, _isAlias, _instruments);

        End If;

    END LOOP;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -- Preview the new info
        SELECT *
        FROM Tmp_Hosts
    Else
        -- Store the host information

        -- Add/update hosts
        MERGE INTO t_bionet_hosts AS t
        USING ( SELECT host, NameOrIP AS IP, Instruments
                FROM Tmp_Hosts
                WHERE Not IsAlias
              ) AS s
        ON (t.host = s.host)
        WHEN MATCHED AND
             (t.ip IS DISTINCT FROM s.ip OR
              t.instruments IS DISTINCT FROM s.instruments) THEN
            UPDATE SET
                ip = s.ip,
                instruments = s.instruments
        WHEN NOT MATCHED THEN
            INSERT (host, ip, instruments)
            VALUES (s.host, s.ip, s.instruments);

        -- Remove out-of-date aliases
        --
        UPDATE t_bionet_hosts Target
        SET alias = Null
        WHERE NOT EXISTS (SELECT Src.Host AS Alias,
                                 Src.NameOrIP AS TargetHost
                          FROM Tmp_Hosts Src
                          WHERE Src.IsAlias And
                                Target.Host = Src.TargetHost AND
                                Target.Alias = Src.Alias)
              AND Not target.Alias Is Null;

        -- Add/update aliases
        --
        UPDATE t_bionet_hosts Target
        SET alias = Src.alias
        FROM ( SELECT Host AS Alias,
                      NameOrIP AS TargetHost
               FROM Tmp_Hosts
               WHERE IsAlias ) Src
        WHERE Target.Host = Src.TargetHost;

    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_HostData;
    DROP TABLE Tmp_Hosts;
    DROP TABLE Tmp_DataColumns;
END
$$;

COMMENT ON PROCEDURE public.store_bionet_hosts IS 'StoreBionetHosts';
