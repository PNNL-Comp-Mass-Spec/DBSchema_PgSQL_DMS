--
CREATE OR REPLACE PROCEDURE public.populate_factor_last_updated
(
    _infoOnly boolean = true,
    _dateFilterStart date = null,
    _dateFilterEnd date = null,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populates the Last_Updated column in table T_Factors using T_Factor_Log
**
**  Auth:   mem
**  Date:   10/06/2016 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _continue boolean;
    _validFactorEntries int := 0;
    _eventID int;
    _eventIDEnd int;
    _changeDate timestamp;
    _factorChanges text;
    _xml xml;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_FactorUpdates
    (
        RequestID int not null,
        FactorType text null,
        FactorName text null,
        FactorValue text null,
        ValidFactor boolean not null
    )

    CREATE INDEX IX_Tmp_FactorUpdates ON Tmp_FactorUpdates (RequestID);

    CREATE TEMP TABLE Tmp_FactorLastUpdated
    (
        RequestID int not null,
        FactorName text not null,
        Last_Updated timestamp not null
    )

    CREATE INDEX IX_Tmp_FactorLastUpdated ON Tmp_FactorLastUpdated (RequestID, FactorName);

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';
    _returnCode:= '';

    If _dateFilterStart Is Null And _dateFilterEnd Is Null Then
        _eventID := -1;

        SELECT MAX(event_id) + 1
        INTO _eventIDEnd
        FROM t_factor_log

        _eventIDEnd := Coalesce(_eventIDEnd, 1000);

    Else
        If Not _dateFilterStart Is Null And _dateFilterEnd Is Null Then
            _dateFilterEnd := '9999-01-01';
        End If;

        If _dateFilterStart Is Null And Not _dateFilterEnd Is Null Then
            _dateFilterStart := '0001-01-01';
        End If;

        _message := format('Finding Factor_Log entries between %s And %s',
                        public.timestamp_text(_dateFilterStart),
                        date_trunc('day', _dateFilterEnd) + Interval '86399.999 seconds');

        If _infoOnly Then
            Select _message as Filter_Message
        Else
            RAISE INFO '%', _message;
        End If;

        SELECT MIN(event_id) - 1
        INTO _eventID
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        SELECT MAX(event_id)
        INTO _eventIDEnd
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';

        _message := '';
    End If;

    -----------------------------------------------------------
    -- Step through the rows in t_factor_log
    -----------------------------------------------------------

    _continue := true;

    WHILE _continue
    LOOP
        -- Find the next row entry for a requested run factor update
        --
        -- This While loop can probably be converted to a For loop; for example:
        --    FOR _itemName IN
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    LOOP
        --        ...
        --    END LOOP

        SELECT changes
        INTO _factorChanges
        FROM t_factor_log
        WHERE event_id > _eventID AND changes like '<r i%'
        ORDER BY event_id
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Or _eventID > _eventIDEnd Then
            _continue := false;
        Else
        -- <b>

            -- Uncomment to preview the raw XML
            -- RAISE INFO '%', _factorChanges;

            -- Example XML:
            -- <r i="141475" f="Virus" v="HPAI" /><r i="141476" f="Virus" v="HPAI" /><r i="141477" f="Virus" v="HPAI" /><r i="138219" f="Virus" v="HPAI" />

            _xml := _factorChanges::xml;

            TRUNCATE TABLE Tmp_FactorUpdates

            INSERT INTO Tmp_FactorUpdates(RequestID, FactorType, FactorName, FactorValue, ValidFactor)
            SELECT XmlQ.RequestID, XmlQ.FactorType, XmlQ.FactorName, XmlQ.FactorValue, false AS ValidFactor
            FROM (
                SELECT xmltable.*
                FROM ( SELECT ('<factors>' || _xml || '</factors>')::xml as rooted_xml
                     ) Src,
                     XMLTABLE('//factors/r'
                              PASSING Src.rooted_xml
                              COLUMNS RequestID int PATH '@i',
                                      FactorType text PATH '@t',
                                      FactorName text PATH '@f',
                                      FactorValue text PATH '@v')
                 ) XmlQ;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            -- Look for valid factor update data
            --
            UPDATE Tmp_FactorUpdates
            SET ValidFactor = true
            WHERE Not Coalesce(FactorType, '')::citext IN ('Block', 'Run Order') AND
                  Not FactorName Is Null;

            If FOUND Then

                _validFactorEntries := _validFactorEntries + 1;

                /*
                 * Uncomment to debug
                If _infoOnly AND _validFactorEntries <= 3 Then
                    SELECT RequestID, FactorName
                    FROM Tmp_FactorUpdates
                    WHERE ValidFactor
                    ORDER BY RequestID, FactorName
                End If;
                */

                -- Merge the changes into Tmp_FactorLastUpdated
                MERGE INTO Tmp_FactorLastUpdated AS t
                USING ( SELECT RequestID, FactorName
                        FROM Tmp_FactorUpdates
                        WHERE ValidFactor
                      ) AS s
                ON (t.RequestID = s.RequestID And t.FactorName = s.FactorName)
                WHEN MATCHED THEN
                    UPDATE SET Last_Updated = _changeDate
                WHEN NOT MATCHED THEN
                    INSERT (RequestID, FactorName, Last_Updated)
                    VALUES (s.RequestID, s.FactorName, _changeDate);

            End If;

        End If; -- </b>
    END LOOP; -- </a>

    If _infoOnly Then
        SELECT Target.*,
               Src.last_updated AS Last_Updated_New
        FROM t_factor Target
             INNER JOIN Tmp_FactorLastUpdated Src
               ON Target.type = 'Run_Request' AND
                  Target.target_id = Src.RequestID AND
                  Target.name = Src.FactorName
        WHERE Src.last_updated <> Target.last_updated
        ORDER BY Target.target_id, Target.name
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else
        UPDATE t_factor
        SET last_updated = Src.last_updated
        FROM t_factor Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_factor
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_factor.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_FactorLastUpdated Src
               ON Target.Type = 'Run_Request' AND
                  Target.TargetID = Src.RequestID AND
                  Target.Name = Src.FactorName
        WHERE Src.Last_Updated <> Target.Last_Updated
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Updated last_updated for ' || Cast(_myRowCount as text) || ' rows in t_factor';
        RAISE INFO '%', _message;
    End If;

    RAISE INFO '%', 'Parsed ' || cast(_validFactorEntries as text) || ' factor log records';

    DROP TABLE Tmp_FactorUpdates;
    DROP TABLE Tmp_FactorLastUpdated;
END
$$;

COMMENT ON PROCEDURE public.populate_factor_last_updated IS 'PopulateFactorLastUpdated';
