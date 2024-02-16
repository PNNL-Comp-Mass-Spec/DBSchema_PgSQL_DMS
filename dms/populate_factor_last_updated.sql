--
-- Name: populate_factor_last_updated(boolean, date, date, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.populate_factor_last_updated(IN _infoonly boolean DEFAULT true, IN _datefilterstart date DEFAULT NULL::date, IN _datefilterend date DEFAULT NULL::date, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populate the last_updated column in table t_factors using t_factor_log
**
**  Arguments:
**    _infoOnly         When true, preview the updates
**    _dateFilterStart  Start date to filter rows in t_factor_log; null to process all rows
**    _dateFilterEnd    End date to filter rows in t_factor_log; null to process all rows
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   10/06/2016 mem - Initial version
**          02/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _validFactorEntries int := 0;
    _eventIDStart int;
    _eventIDEnd int;
    _changeDate timestamp;
    _factorChanges text;
    _eventID int;
    _xml xml;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_FactorUpdates (
        RequestID int not null,
        FactorType text null,
        FactorName text null,
        FactorValue text null,
        ValidFactor boolean not null
    );

    CREATE INDEX IX_Tmp_FactorUpdates ON Tmp_FactorUpdates (RequestID);

    CREATE TEMP TABLE Tmp_FactorLastUpdated (
        RequestID int not null,
        FactorName text not null,
        Last_Updated timestamp not null
    );

    CREATE INDEX IX_Tmp_FactorLastUpdated ON Tmp_FactorLastUpdated (RequestID, FactorName);

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    RAISE INFO '';

    If _dateFilterStart Is Null And _dateFilterEnd Is Null Then
        _eventIDStart := -1;

        SELECT MAX(event_id) + 1
        INTO _eventIDEnd
        FROM t_factor_log;

        _eventIDEnd := Coalesce(_eventIDEnd, 1000);

        RAISE INFO 'Processing all entries in factor_log';
    Else
        If Not _dateFilterStart Is Null And _dateFilterEnd Is Null Then
            _dateFilterEnd := '9999-01-01'::date;
        End If;

        If _dateFilterStart Is Null And Not _dateFilterEnd Is Null Then
            _dateFilterStart := '0001-01-01'::date;
        End If;

        RAISE INFO 'Processing factor_log entries between % and %',
                        public.timestamp_text(_dateFilterStart),
                        public.timestamp_text(_dateFilterEnd + Interval '86399.999 seconds');

        SELECT MIN(event_id) - 1
        INTO _eventIDStart
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';

        SELECT MAX(event_id)
        INTO _eventIDEnd
        FROM t_factor_log
        WHERE changed_on BETWEEN _dateFilterStart AND _dateFilterEnd + INTERVAL '1 day';
    End If;

    -----------------------------------------------------------
    -- Step through the rows in t_factor_log
    -----------------------------------------------------------

    FOR _eventID, _changeDate, _factorChanges IN
        SELECT event_id, changed_on, changes
        FROM t_factor_log
        WHERE event_id BETWEEN _eventIDStart AND _eventIDEnd AND changes LIKE '<r i%'
        ORDER BY event_id
    LOOP
        -- Uncomment to preview the raw XML
        -- RAISE INFO '%', _factorChanges;

        -- Example XML:
        -- <r i="141475" f="Virus" v="HPAI" /><r i="141476" f="Virus" v="HPAI" /><r i="141477" f="Virus" v="HPAI" /><r i="138219" f="Virus" v="HPAI" />
        -- <r i="1273564" t="block" v="1" /><r i="1273565" t="block" v="2" /><r i="1273566" t="block" v="3" /><r i="1273567" t="block" v="4" /><r i="1273564" t="Run Order" v="" /><r i="1273565" t="Run Order" v="" /><r i="1273566" t="Run Order" v="" /><r i="1273567" t="Run Order" v="" />
        -- <r i="1273564" t="Run Order" v="1" /><r i="1273600" t="Run Order" v="2" /><r i="1273624" t="Run Order" v="3" /><r i="1273648" t="Run Order" v="4" />

        _xml := public.try_cast(_factorChanges, null::xml);

        If _xml Is Null Then
            RAISE WARNING 'Invalid XML for event_id % in t_factor_log: %',
                            _eventID,
                            CASE WHEN char_length(_factorChanges) > 100
                                 THEN Left(_factorChanges, 100) || '...'
                                 ELSE _factorChanges
                            END;
            CONTINUE;
        End If;

        TRUNCATE TABLE Tmp_FactorUpdates;

        INSERT INTO Tmp_FactorUpdates(RequestID, FactorType, FactorName, FactorValue, ValidFactor)
        SELECT XmlQ.RequestID, XmlQ.FactorType, XmlQ.FactorName, XmlQ.FactorValue, false AS ValidFactor
        FROM (
            SELECT xmltable.*
            FROM ( SELECT ('<factors>' || _xml || '</factors>')::xml As rooted_xml
                 ) Src,
                 XMLTABLE('//factors/r'
                          PASSING Src.rooted_xml
                          COLUMNS RequestID int PATH '@i',
                                  FactorType text PATH '@t',
                                  FactorName text PATH '@f',
                                  FactorValue text PATH '@v')
             ) XmlQ;

        -- Look for valid factor update data

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
        If _infoOnly And _validFactorEntries <= 3 Then
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
        RAISE INFO '';

        If Not Exists (SELECT Target.Factor_ID
                       FROM t_factor Target
                            INNER JOIN Tmp_FactorLastUpdated Src
                              ON Target.type = 'Run_Request' AND
                                 Target.target_id = Src.RequestID AND
                                 Target.name = Src.FactorName
                       WHERE Src.last_updated <> Target.last_updated)
        Then
            RAISE INFO 'Did not find any factors to update';
        Else
            _formatSpecifier := '%-15s %-15s %-15s %-30s %-40s %-20s %-20s %-11s';

            _infoHead := format(_formatSpecifier,
                                'Factor_ID',
                                'Type',
                                'Target_ID',
                                'Name',
                                'Value',
                                'Last_Updated_Old',
                                'Last_Updated_New',
                                'Change_Days'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------------',
                                         '---------------',
                                         '---------------',
                                         '------------------------------',
                                         '----------------------------------------',
                                         '--------------------',
                                         '--------------------',
                                         '-----------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Target.Factor_ID,
                       Target.Type,
                       Target.Target_ID,
                       Target.Name,
                       Target.Value,
                       Target.last_updated AS Last_Updated_Old,
                       Src.last_updated AS Last_Updated_New
                FROM t_factor Target
                     INNER JOIN Tmp_FactorLastUpdated Src
                       ON Target.type = 'Run_Request' AND
                          Target.target_id = Src.RequestID AND
                          Target.name = Src.FactorName
                WHERE Src.last_updated <> Target.last_updated
                ORDER BY Target.target_id, Target.name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Factor_ID,
                                    _previewData.Type,
                                    _previewData.Target_ID,
                                    _previewData.Name,
                                    _previewData.Value,
                                    public.timestamp_text(_previewData.Last_Updated_Old),
                                    public.timestamp_text(_previewData.Last_Updated_New),
                                    Round(extract(epoch FROM _previewData.Last_Updated_Old - _previewData.Last_Updated_New) / 3600.0 / 24.0, 2)
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;
    Else
        UPDATE t_factor Target
        SET last_updated = Src.last_updated
        FROM Tmp_FactorLastUpdated Src
        WHERE Target.type = 'Run_Request' AND
              Target.target_id = Src.RequestID AND
              Target.name = Src.FactorName AND
              Src.Last_Updated IS DISTINCT FROM Target.last_updated;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Updated last_updated for %s %s in t_factor', _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

    RAISE INFO '';
    RAISE INFO 'Parsed % factor log records', _validFactorEntries;

    DROP TABLE Tmp_FactorUpdates;
    DROP TABLE Tmp_FactorLastUpdated;
END
$$;


ALTER PROCEDURE public.populate_factor_last_updated(IN _infoonly boolean, IN _datefilterstart date, IN _datefilterend date, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE populate_factor_last_updated(IN _infoonly boolean, IN _datefilterstart date, IN _datefilterend date, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.populate_factor_last_updated(IN _infoonly boolean, IN _datefilterstart date, IN _datefilterend date, INOUT _message text, INOUT _returncode text) IS 'PopulateFactorLastUpdated';

