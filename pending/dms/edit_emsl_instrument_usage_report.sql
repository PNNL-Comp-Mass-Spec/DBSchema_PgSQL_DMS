--
CREATE OR REPLACE PROCEDURE public.edit_emsl_instrument_usage_report
(
    _year int = 2012,
    _month int = 8,
    _instrument text = '',
    _type text = '',
    _usage text = '',
    _proposal text = '',
    _users text = '',
    _operator text = '',
    _comment text = '',
    _fieldName text = '',
    _newValue text = '',
    _doUpdate int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates selected EMSL instrument usage report items
**
**      This procedure appears to be unused in 2017
**
**  Arguments:
**    _operator    Operator for update (should be an integer representing EUS Person ID; if an empty string, will store NULL for the operator ID)
**    _fieldName   Proposal, Usage, Users, Operator, Comment
**
**  Auth:   grk
**  Date:   08/31/2012 grk - Initial release
**          09/11/2012 grk - Fixed update SQL
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _instrumentID int := 0;
    _usageTypeID int := 0;
    _newUsageTypeID int := 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
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

    -- Assure that _operator is either an integer or null
    _operator := public.try_cast(_operator, null::int);

    _newValue := Trim(Coalesce(_newValue, ''));

    If _instrument <> '' Then
        SELECT instrument_id
        INTO _instrumentID
        FROM t_instrument_name
        WHERE instrument = _instrument;

        If _instrumentID = 0 Then
            RAISE EXCEPTION 'Instrument not found: "%"', _instrument;
        End If;
    End If;

    If _usage <> '' Then
        SELECT usage_type_id
        INTO _usageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _usage;

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
    WHERE MONTH = _month AND
          YEAR = _year AND
          (_instrumentID = 0 OR dms_inst_id = _instrumentID) AND
          (_type = '' OR type = _type) AND
          (_usageTypeID = 0 OR usage_type_id = _usageTypeID) AND
          (_proposal = '' OR proposal = _proposal) AND
          (_users = '' OR users = _users) AND
          (_operator IS NULL OR operator = _operator);

    ---------------------------------------------------
    -- Display affected items or make change
    ---------------------------------------------------

    If _doUpdate = 0 Then

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

    If _fieldName = 'Proposal' Then
        UPDATE TD
        SET proposal = _newValue
        FROM t_emsl_instrument_usage_report TD INNER JOIN
             Tmp_InstrumentUsageInfo ON Tmp_InstrumentUsageInfo.seq = TD.seq;
    End If;

    If _fieldName = 'Usage' And _newValue <> '' Then
        SELECT usage_type_id
        INTO _newUsageTypeID
        FROM t_emsl_instrument_usage_type
        WHERE usage_type = _newValue;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid usage type: "%"', _newValue;
        Else
            UPDATE TD
            SET usage_type_id = _newUsageTypeID
            FROM t_emsl_instrument_usage_report TD INNER JOIN
                 Tmp_InstrumentUsageInfo ON Tmp_InstrumentUsageInfo.seq = TD.seq;
        End If;
    End If;

    If _fieldName = 'Users' Then
        UPDATE TD
        SET users = _newValue
        FROM t_emsl_instrument_usage_report TD INNER JOIN
             Tmp_InstrumentUsageInfo ON Tmp_InstrumentUsageInfo.seq = TD.seq;
    End If;

    If _fieldName = 'Operator' Then
        -- Store null if _newValue is not an integer
        UPDATE TD
        SET operator = Try__newValue::int
        FROM t_emsl_instrument_usage_report TD INNER JOIN
             Tmp_InstrumentUsageInfo ON Tmp_InstrumentUsageInfo.seq = TD.seq;
    End If;

    If _fieldName = 'Comment' Then
        UPDATE TD
        SET comment = _newValue
        FROM t_emsl_instrument_usage_report TD INNER JOIN
             Tmp_InstrumentUsageInfo ON Tmp_InstrumentUsageInfo.seq = TD.seq
    End If;

    DROP TABLE Tmp_InstrumentUsageInfo;
END
$$;

COMMENT ON PROCEDURE public.edit_emsl_instrument_usage_report IS 'EditEMSLInstrumentUsageReport';
