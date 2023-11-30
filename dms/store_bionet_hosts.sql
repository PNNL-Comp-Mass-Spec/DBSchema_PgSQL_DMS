--
-- Name: store_bionet_hosts(text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_bionet_hosts(IN _hostlist text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entries in t_bionet_hosts
**
**      Prior to 2022, Gigasax was the DNS server for Bionet
**      - Computers on Bionet could be exported from the DNS management console by right clicking Bionet under "Forward Lookup Zones" and choosing "Export list ..."
**      - This procedure can read the exported data and update table t_bionet_hosts
**
**      File format (tab-separated) for the file created using "Export list ..." on the DNS server running on Gigasax
**
**         Name    Type    Data
**         (same as parent folder)       Start of Authority (SOA)   [1517], gigasax.bionet.,
**         (same as parent folder)       Name Server (NS)   gigasax.bionet.
**         (same as parent folder)       Host (A)   192.168.30.0
**         12t_fticr_p    Host (A)       192.168.30.81
**         15t_fticr_i    Host (A)       192.168.30.54
**         ag_gc_ms_01    Host (A)       192.168.30.69
**         ag_gc_ms_02    Host (A)       192.168.30.70
**         ag_gc_ms_03    Host (A)       192.168.30.79
**         prephplc6      Host (A)       192.168.30.212
**         prephplc7      Host (A)       192.168.30.213
**         prismbb        Alias (CNAME)  prismweb3.bionet.
**
**
**      In 2022 we switched to using webmin on PrismDB1 for DNS, including supporting DHCP
**      - For info, see https://prismwiki.pnl.gov/wiki/Webmin
**      - Active hosts tracked by DNS are listed in /var/named/bionet.hosts
**
**      Command to view the computer names and IPs in bionet.hosts, filtering on entries of type "A" or "CNAME"
**      cat /var/named/bionet.hosts | ag "\t(A|CNAME)\t"
**      cat /var/named/bionet.hosts | ag "\t(A|CNAME)\t" > ~/Bionet_Hosts.txt
**
**      File bionet.hosts is a tab-separated file, but the number of tabs between the instrument name, type name, and data value can vary
**      This procedure handles this by replacing instances of two tabs in a row with a single tab
**
**         12t_fticr_p             A       192.168.30.81
**         15t_fticr_i             A       192.168.30.54
**         ag_gc_ms_01             A       192.168.30.69
**         ag_gc_ms_02             A       192.168.30.70
**         ag_gc_ms_03             A       192.168.30.79
**         prephplc6               A       192.168.30.212
**         prephplc7               A       192.168.30.213
**         PrepHPLC8               A       192.168.30.113
**         prismbb                 CNAME   prismweb3
**
**  Arguments:
**    _hostList     Lists of host names and IPs, from either Gigasax or bionet.hosts
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   12/02/2015 mem - Initial version
**          11/19/2018 mem - Pass 0 to the _maxRows parameter of parse_delimited_list_ordered
**          11/29/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _lineDelimiter text;
    _tabDelimiter text;
    _entryIDEnd int := 0;

    _rowNumber int;
    _row text;
    _i int;
    _columnCount int := 0;

    _hostName citext;
    _hostType citext;
    _hostData citext;
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
    -- Validate the inputs
    -----------------------------------------

    _hostList := Trim(Coalesce(_hostList, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    If _hostList = '' Then
        _message := '_hostList is empty; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_HostData (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Value text null
    );

    CREATE UNIQUE INDEX IX_Tmp_HostData_EntryID ON Tmp_HostData (EntryID);

    CREATE TEMP TABLE Tmp_Hosts (
        Host citext not null,
        NameOrIP citext not null,
        IsAlias boolean not null,
        Instruments citext null
    );

    CREATE UNIQUE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host);

    CREATE TEMP TABLE Tmp_DataColumns (
        EntryID int not null,
        Value citext null
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
    SELECT Value
    FROM public.parse_delimited_list(_hostList, _lineDelimiter);

    If Not Exists (SELECT * FROM Tmp_HostData) Then
        _message := 'Nothing returned when splitting the Host List on CR or LF';
        _returnCode := 'U5202';

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

    _rowNumber := 0;

    FOR _row IN
        SELECT Value
        FROM Tmp_HostData
        ORDER BY EntryID
    LOOP

        _rowNumber := _rowNumber + 1;

        -- _row should now be empty, or contain something like the following (tab-separated values):
        -- 12tfticr64    Host (A)    192.168.30.54
        --   or
        -- agilent_qtof_02    Alias (CNAME)    agqtof02.bionet.
        --   or
        -- qehfx03                 A       192.168.30.97

        _row := Replace (_row, chr(10), '');
        _row := Replace (_row, chr(13), '');
        _row := Trim(Coalesce(_row, ''));

        If Coalesce(_row, '') = '' Then
            CONTINUE;
        End If;

        If Position(chr(10) IN _row) > 0 Then
            -- Rows in file /var/named/bionet.host can have a varying number of columns
            -- Replace cases of two tabs side-by-side with a single tab
            -- Do this replacement three times

            -- Uncomment to debug
            -- If _rowNumber < 5 Then
            --    RAISE INFO 'Checking for adjacent tabs in row %', _rowNumber;
            -- End If;

            FOR _i IN 1 .. 3
            LOOP
                _row := Replace (_row, chr(10) || chr(10), chr(10));
            END LOOP;
        ElsIf Position(' ' IN _row) > 0 Then
            -- When tab-delimited text is pasted into DBeaver, it changes the tabs to spaces
            -- Change spaces back to tabs

            -- Uncomment to debug
            -- If _rowNumber < 5 Then
            --     RAISE INFO 'Replacing spaces with tabs in row %', _rowNumber;
            -- End If;

            _row := regexp_replace(_row, '[ ]+', _tabDelimiter, 'g');
        End If;

        -- Split the row on tabs to find HostName, HostType, and HostData
        TRUNCATE TABLE Tmp_DataColumns;

        INSERT INTO Tmp_DataColumns (EntryID, Value)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_row, _tabDelimiter, 0);
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

        If _hostName = '(same as parent folder)' Or (_hostName = 'Name' And _hostType = 'Type') Then
            -- Skip this line
            CONTINUE;
        End If;

        If _hostType = 'CNAME' Or _hostType Like 'Alias%' Then
            _isAlias := true;

            If _hostData Like '%.' Then
                -- Alias name ends in a period; remove it
                _hostData := Substring(_hostData, 1, char_length(_hostData) - 1);
            End If;

            If _hostData Like '%.bionet' Then
                -- Alias name ends '.bionet'; remove that suffix
                _hostData := Substring(_hostData, 1, char_length(_hostData) - char_length('.bionet'));
            End If;
        End If;

        -- Look for instruments that have an inbox on this host
        --
        SELECT string_agg(Inst.instrument, ', ' ORDER BY Inst.instrument)
        INTO _instruments
        FROM t_storage_path SPath
             INNER JOIN t_instrument_name Inst
               ON SPath.storage_path_id = Inst.source_path_id
        WHERE SPath.machine_name = _hostName OR SPath.machine_name = format('%s.bionet', _hostName)::citext AND
              SPath.storage_path_function ILIKE '%inbox%';

        INSERT INTO Tmp_Hosts (Host, NameOrIP, IsAlias, Instruments)
        VALUES (_hostName, _hostData, _isAlias, _instruments);

    END LOOP;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-20s %-8s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Host',
                            'Name_or_IP',
                            'Is_Alias',
                            'Instruments'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '--------------------',
                                     '--------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Host,
                   NameOrIP As Name_or_IP,
                   IsAlias As Is_Alias,
                   Instruments
            FROM Tmp_Hosts
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Host,
                                _previewData.Name_or_IP,
                                _previewData.Is_Alias,
                                _previewData.Instruments
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

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

        UPDATE t_bionet_hosts Target
        SET alias = Null
        WHERE NOT EXISTS (SELECT 1
                          FROM Tmp_Hosts Src
                          WHERE Src.IsAlias AND
                                Target.Host = Src.NameOrIP AND
                                Target.Alias = Src.Host)
              AND Not target.Alias Is Null;

        -- Add/update aliases

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


ALTER PROCEDURE public.store_bionet_hosts(IN _hostlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_bionet_hosts(IN _hostlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_bionet_hosts(IN _hostlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'StoreBionetHosts';

