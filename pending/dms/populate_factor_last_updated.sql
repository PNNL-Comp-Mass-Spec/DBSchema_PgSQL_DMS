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
    _updateCount int;
    _validFactorEntries int := 0;
    _eventIDStart int;
    _eventIDEnd int;
    _changeDate timestamp;
    _factorChanges text;
    _eventID int
    _xml xml;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
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
    );

    CREATE INDEX IX_Tmp_FactorUpdates ON Tmp_FactorUpdates (RequestID);

    CREATE TEMP TABLE Tmp_FactorLastUpdated
    (
        RequestID int not null,
        FactorName text not null,
        Last_Updated timestamp not null
    );

    CREATE INDEX IX_Tmp_FactorLastUpdated ON Tmp_FactorLastUpdated (RequestID, FactorName);

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';
    _returnCode:= '';

    If _dateFilterStart Is Null And _dateFilterEnd Is Null Then
        _eventIDStart := -1;

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

        _message := format('Finding Factor_Log entries between %s and %s',
                        public.timestamp_text(_dateFilterStart),
                        date_trunc('day', _dateFilterEnd) + Interval '86399.999 seconds');

        RAISE INFO '%', _message;

        SELECT MIN(event_id) - 1
        INTO _eventIDStart
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';

        SELECT MAX(event_id)
        INTO _eventIDEnd
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';

        _message := '';
    End If;

    -----------------------------------------------------------
    -- Step through the rows in t_factor_log
    -----------------------------------------------------------

    FOR _factorChanges, _eventID IN
        SELECT changes, event_id
        FROM t_factor_log
        WHERE event_id >= _eventIDStart AND changes LIKE '<r i%'
        ORDER BY event_id
    LOOP

        If _eventID > _eventIDEnd Then
            -- Break out of the For loop
            EXIT;
        End If;

        -- Uncomment to preview the raw XML
        -- RAISE INFO '%', _factorChanges;

        -- Example XML:
        -- <r i="141475" f="Virus" v="HPAI" /><r i="141476" f="Virus" v="HPAI" /><r i="141477" f="Virus" v="HPAI" /><r i="138219" f="Virus" v="HPAI" />

        _xml := _factorChanges::xml;

        TRUNCATE TABLE Tmp_FactorUpdates;

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

        -- Look for valid factor update data
        --
        UPDATE Tmp_FactorUpdates
        SET ValidFactor = true
        WHERE Not Coalesce(FactorType, '')::citext IN ('Block', 'Run Order') AND
              Not FactorName Is Null;

        If Not FOUND Then
            CONTINUE;
        End If;

        _validFactorEntries := _validFactorEntries + 1;

        /*
         * Uncomment to debug
        If _infoOnly AND _validFactorEntries <= 3 Then
            FOR _requestID, _factorName IN
                SELECT RequestID, FactorName
                FROM Tmp_FactorUpdates
                WHERE ValidFactor
                ORDER BY RequestID, FactorName
            LOOP
                RAISE INFO 'Request ID %, factor %', _requestID, _factorName;
            END LOOP;
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

    END LOOP;

    If _infoOnly Then

        _formatSpecifier := '%-15s %-15s %-15s %-30s %-40s %-16s';

        _infoHead := format(_formatSpecifier,
                            'Factor_ID',
                            'Type',
                            'Target_ID',
                            'Name',
                            'Value',
                            'Last_Updated_New'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                            '---------------',
                            '---------------',
                            '---------------',
                            '------------------------------',
                            '----------------------------------------',
                            '----------------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Target.Factor_ID,
                   Target.Type,
                   Target.Target_ID,
                   Target.Name,
                   Target.Value,
                   Src.last_updated AS Last_Updated_New
            FROM t_factor Target
                 INNER JOIN Tmp_FactorLastUpdated Src
                   ON Target.type = 'Run_Request' AND
                      Target.target_id = Src.RequestID AND
                      Target.name = Src.FactorName
            WHERE Src.last_updated <> Target.last_updated
            ORDER BY Target.target_id, Target.name
        LOOP
            RAISE INFO '%', format(_formatSpecifier,
                                    _previewData.Factor_ID,
                                    _previewData.Type,
                                    _previewData.Target_ID,
                                    _previewData.Name,
                                    _previewData.Value,
                                    _previewData.Last_Updated_New
                                );
        END LOOP;

    Else
        UPDATE t_factor
        SET last_updated = Src.last_updated
        FROM Tmp_FactorLastUpdated Src
        WHERE Target.Type = 'Run_Request' AND
              Target.TargetID = Src.RequestID AND
              Target.Name = Src.FactorName AND
              Src.Last_Updated IS DISTINCT FROM Target.Last_Updated
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Updated last_updated for %s %s in t_factor', _updateCount, public.check_plural(_updateCount, 'row', 'rows');
        RAISE INFO '%', _message;
    End If;

    RAISE INFO 'Parsed % factor log records', _validFactorEntries;

    DROP TABLE Tmp_FactorUpdates;
    DROP TABLE Tmp_FactorLastUpdated;
END
$$;

COMMENT ON PROCEDURE public.populate_factor_last_updated IS 'PopulateFactorLastUpdated';
