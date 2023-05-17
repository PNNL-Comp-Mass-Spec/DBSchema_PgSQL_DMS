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
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to udfParseDelimitedListOrdered
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _columnCount int := 0;
    _delimiter text;
    _entryID int := 0;
    _entryIDEnd int := 0;
    _charIndex int;
    _colCount int;
    _row text;
    _hostName text;
    _hostType text;
    _hostData text;
    _instruments text;
    _isAlias int;
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
        IsAlias int not null,
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
        _delimiter := chr(10);
    Else
        _delimiter := chr(13);
    End If;

    INSERT INTO Tmp_HostData (Value)
    SELECT Item
    FROM public.parse_delimited_list ( _hostList, _delimiter )

    If Not Exists (SELECT * FROM Tmp_HostData) Then
        _message := 'Nothing returned when splitting the Host List on CR or LF';
        returnCode := 'U5202'

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
    --
    WHILE _entryID < _entryIDEnd
    LOOP
        -- This While loop can probably be converted to a For loop; for example:
        --    FOR _itemName IN
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    LOOP
        --        ...
        --    END LOOP

        SELECT Value
        INTO _row
        FROM Tmp_HostData
        WHERE EntryID > _entryID
        ORDER BY EntryID
        LIMIT 1;

        -- _row should now be empty, or contain something like the following:
        -- 12tfticr64    Host (A)    192.168.30.54
        --   or
        -- agilent_qtof_02    Alias (CNAME)    agqtof02.

        _row := Replace (_row, chr(10), '');
        _row := Replace (_row, chr(13), '');
        _row := Trim(Coalesce(_row, ''));

        If _row <> '' Then

            -- Split the row on tabs to find HostName, HostType, and HostData
            TRUNCATE TABLE Tmp_DataColumns
            _delimiter := text;

            INSERT INTO Tmp_DataColumns (EntryID, Value)
            SELECT Entry_ID, Value
            FROM public.parse_delimited_list_ordered(_row, _delimiter, 0)
            --
            GET DIAGNOSTICS _columnCount = ROW_COUNT;

            If _columnCount < 3 Then
                RAISE INFO '%', 'Skipping row since less than 3 columns: ' || _row;
                CONTINUE;
            End If;

            _hostName := '';
            _hostType := '';
            _hostData := '';
            _instruments := '';
            _isAlias := 0;

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


            If _hostName = '' or _hostType = '' Or _hostData = '' Then
                RAISE INFO '%', 'Skipping row since 1 or more columns are blank: ' || _row;
            Else
                If _hostName <> '(same as parent folder)' And Not (_hostName = 'Name' And _hostType = 'Type') Then
                    If _hostType Like 'Alias%' Then
                        _isAlias := 1;

                        If _hostData Like '%.' Then
                            _hostData := SubString(_hostData, 1, char_length(_hostData)-1);
                        End If;
                    End If;

                    -- Look for instruments that have an inbox on this host
                    --
                    SELECT string_agg(Inst.instrument, ', ', Inst.instrument)
                    INTO _instruments
                    FROM t_storage_path SPath
                         INNER JOIN t_instrument_name Inst
                           ON SPath.storage_path_id = Inst.source_path_id
                    WHERE (SPath.machine_name = _hostName OR SPath.machine_name = _hostName || '.bionet') AND
                          (SPath.storage_path_function LIKE '%inbox%');

                    If char_length(_instruments) > 0 Then
                        _instruments := Substring(_instruments, 3, char_length(_instruments));
                    End If;

                    INSERT INTO Tmp_Hosts (Host, NameOrIP, IsAlias, Instruments)
                    VALUES (_hostName, _hostData, _isAlias, _instruments);

                End If;
            End If;

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
                WHERE IsAlias = 0
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
                          WHERE Src.IsAlias = 1 And
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
               WHERE IsAlias = 1 ) Src
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
