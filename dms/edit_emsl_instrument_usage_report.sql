--
-- Name: edit_emsl_instrument_usage_report(integer, integer, text, text, text, text, text, text, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.edit_emsl_instrument_usage_report(IN _year integer DEFAULT 2012, IN _month integer DEFAULT 8, IN _instrument text DEFAULT ''::text, IN _type text DEFAULT ''::text, IN _usage text DEFAULT ''::text, IN _proposal text DEFAULT ''::text, IN _users text DEFAULT ''::text, IN _operator text DEFAULT ''::text, IN _fieldname text DEFAULT ''::text, IN _newvalue text DEFAULT ''::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update selected EMSL instrument usage report items
**
**      This procedure appears to be unused in 2017
**
**  Arguments:
**    _year         Year
**    _month        Month
**    _instrument   Instrument name;                     if an empty string, do not filter on instrument name
**    _type         Usage type: 'Dataset' or 'Interval'; if an empty string, do not filter on usage type
**    _usage        EUS usage type name;                 if an empty string, do not filter on usage type
**    _proposal     EUS proposal, e.g. '60045';          if an empty string, do not filter on proposals
**    _users        EUS user ID, e.g. '52597';           if an empty string, do not filter on user ID; typically only a single user, but can also be a list of users, e.g. '43787, 49612'
**    _operator     Operator for update, corresponding to person_id in t_eus_users (should be an integer representing EUS Person ID); if an empty string, will store NULL for the operator ID
**    _fieldName    Field name: 'Proposal', 'Usage', 'Users', 'Operator', 'Comment'
**    _newValue     Field value
**    _infoOnly     When true, preview the update
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   08/31/2012 grk - Initial version
**          09/11/2012 grk - Fixed update SQL
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/13/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _operatorID int;
    _instrumentID int := 0;
    _usageTypeID int := 0;
    _newUsageTypeID int := 0;
    _updateCount int = 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _month      := Coalesce(_month, 0);
    _year       := Coalesce(_year, 0);

    _instrument := Trim(Coalesce(_instrument, ''));
    _type       := Trim(Coalesce(_type, ''));
    _usage      := Trim(Coalesce(_usage, ''));
    _proposal   := Trim(Coalesce(_proposal, ''));
    _users      := Trim(Coalesce(_users, ''));
    _fieldName  := Trim(Coalesce(_fieldName, ''));

    -- Assure that _operator is either an integer or null
    _operatorID := public.try_cast(_operator, null::int);

    _newValue := Trim(Coalesce(_newValue, ''));

    If _instrument <> '' Then
        SELECT instrument_id
        INTO _instrumentID
        FROM t_instrument_name
        WHERE instrument = _instrument::citext;

        If _instrumentID = 0 Then
            RAISE EXCEPTION 'Instrument not found: "%"', _instrument;
        End If;
    End If;

    If _usage <> '' Then
        SELECT usage_type_id
        INTO _usageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _usage::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Usage type not found: "%"', _usage;
        End If;
    End If;

    ---------------------------------------------------
    -- Temp table to hold keys to affected items
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_InstrumentUsageInfo (
        Seq int
    );

    ---------------------------------------------------
    -- Get keys to affected items
    ---------------------------------------------------

    INSERT INTO Tmp_InstrumentUsageInfo( seq )
    SELECT seq
    FROM t_emsl_instrument_usage_report
    WHERE month = _month AND
          year = _year AND
          (_instrumentID = 0 OR dms_inst_id = _instrumentID) AND
          (_type = '' OR type = _type::citext) AND
          (_usageTypeID = 0 OR usage_type_id = _usageTypeID) AND
          (_proposal = '' OR proposal = _proposal::citext) AND
          (_users = '' OR users = _users::citext) AND
          (_operatorID IS NULL OR operator = _operatorID);

    If Not FOUND Then
        _message = 'Did not find any usage report entries matching the filters';
        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_InstrumentUsageInfo;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Display affected items or make change
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-12s %-12s %-8s %-20s %-8s %-10s %-13s %-15s %-10s %-20s %-4s %-5s %-10s %-22s';

        _infoHead := format(_formatSpecifier,
                            'Seq',
                            'EMSL_Inst_ID',
                            'DMS_Inst_ID',
                            'Type',
                            'Start',
                            'Minutes',
                            'Proposal',
                            'Usage_Type_ID',
                            'Users',
                            'Operator',
                            'Comment',
                            'Year',
                            'Month',
                            'Dataset_ID',
                            'Dataset_ID_Acq_Overlap'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '------------',
                                     '------------',
                                     '--------',
                                     '--------------------',
                                     '--------',
                                     '----------',
                                     '-------------',
                                     '---------------',
                                     '----------',
                                     '--------------------',
                                     '----',
                                     '-----',
                                     '----------',
                                     '----------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT R.Seq,
                   R.EMSL_Inst_ID,
                   R.DMS_Inst_ID,
                   R.Type,
                   public.timestamp_text(R.Start) As Start,
                   R.Minutes,
                   R.Proposal,
                   R.Usage_Type_ID,
                   R.Users,
                   R.Operator,
                   R.Comment,
                   R.Year,
                   R.Month,
                   R.Dataset_ID,
                   R.Dataset_ID_Acq_Overlap
            FROM Tmp_InstrumentUsageInfo InstInfo
                 INNER JOIN t_emsl_instrument_usage_report R
                   ON InstInfo.seq = R.seq
            ORDER BY R.seq
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Seq,
                                _previewData.EMSL_Inst_ID,
                                _previewData.DMS_Inst_ID,
                                _previewData.Type,
                                _previewData.Start,
                                _previewData.Minutes,
                                _previewData.Proposal,
                                _previewData.Usage_Type_ID,
                                _previewData.Users,
                                _previewData.Operator,
                                _previewData.Comment,
                                _previewData.Year,
                                _previewData.Month,
                                _previewData.Dataset_ID,
                                _previewData.Dataset_ID_Acq_Overlap
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_InstrumentUsageInfo;
        RETURN;
    End If;

    If _fieldName::citext = 'Proposal' Then
        UPDATE t_emsl_instrument_usage_report TD
        SET proposal = _newValue,
            updated = CURRENT_TIMESTAMP
        FROM Tmp_InstrumentUsageInfo
        WHERE Tmp_InstrumentUsageInfo.seq = TD.seq;

        GET DIAGNOSTICS _updateCount = ROW_COUNT;
    End If;

    If _fieldName::citext = 'Usage' And _newValue <> '' Then
        SELECT usage_type_id
        INTO _newUsageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _newValue::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid usage type: "%"', _newValue;
        Else
            UPDATE t_emsl_instrument_usage_report TD
            SET usage_type_id = _newUsageTypeID,
                updated = CURRENT_TIMESTAMP
            FROM Tmp_InstrumentUsageInfo
            WHERE Tmp_InstrumentUsageInfo.seq = TD.seq;

            GET DIAGNOSTICS _updateCount = ROW_COUNT;
        End If;
    End If;

    If _fieldName::citext = 'Users' Then
        UPDATE t_emsl_instrument_usage_report TD
        SET users = _newValue,
            updated = CURRENT_TIMESTAMP
        FROM Tmp_InstrumentUsageInfo
        WHERE Tmp_InstrumentUsageInfo.seq = TD.seq;

        GET DIAGNOSTICS _updateCount = ROW_COUNT;
    End If;

    If _fieldName::citext = 'Operator' Then
        UPDATE t_emsl_instrument_usage_report TD
        SET operator = public.try_cast(_newValue, null::int),    -- Store null if _newValue is not an integer
            updated = CURRENT_TIMESTAMP
        FROM Tmp_InstrumentUsageInfo
        WHERE Tmp_InstrumentUsageInfo.seq = TD.seq;

        GET DIAGNOSTICS _updateCount = ROW_COUNT;
    End If;

    If _fieldName::citext = 'Comment' Then
        UPDATE t_emsl_instrument_usage_report TD
        SET comment = _newValue,
            updated = CURRENT_TIMESTAMP
        FROM Tmp_InstrumentUsageInfo
        WHERE Tmp_InstrumentUsageInfo.seq = TD.seq;

        GET DIAGNOSTICS _updateCount = ROW_COUNT;
    End If;

    If _updateCount = 0 Then
        _message = format('Did not update any rows; invalid target field name: %s', _fieldName);
    Else
        _message = format('Updated %s in %s %s', Lower(_fieldName), _updateCount, public.check_plural(_updateCount, 'row', 'rows'));
    End If;

    RAISE INFO '';
    RAISE INFO '%', _message;

    DROP TABLE Tmp_InstrumentUsageInfo;
END
$$;


ALTER PROCEDURE public.edit_emsl_instrument_usage_report(IN _year integer, IN _month integer, IN _instrument text, IN _type text, IN _usage text, IN _proposal text, IN _users text, IN _operator text, IN _fieldname text, IN _newvalue text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE edit_emsl_instrument_usage_report(IN _year integer, IN _month integer, IN _instrument text, IN _type text, IN _usage text, IN _proposal text, IN _users text, IN _operator text, IN _fieldname text, IN _newvalue text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.edit_emsl_instrument_usage_report(IN _year integer, IN _month integer, IN _instrument text, IN _type text, IN _usage text, IN _proposal text, IN _users text, IN _operator text, IN _fieldname text, IN _newvalue text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'EditEMSLInstrumentUsageReport';

