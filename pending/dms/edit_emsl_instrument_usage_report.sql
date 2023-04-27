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
**    _fieldName   Proposal, Usage,  Users,  Operator,  Comment,
**
**  Auth:   grk
**  Date:   08/31/2012 grk - Initial release
**          09/11/2012 grk - fixed update SQL
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _instrumentID int := 0;
    _usageTypeID int := 0;
    _newUsageTypeID int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _month := Coalesce(_month, 0);
    _year := Coalesce(_year, 0);

    _instrument := Coalesce(_instrument, '');
    _type := Coalesce(_type, '');
    _usage := Coalesce(_usage, '');
    _proposal := Coalesce(_proposal, '');
    _users := Coalesce(_users, '');

    -- Assure that _operator is either an integer or null
    _operator := try_cast(_operator, null::int);

    _newValue := Coalesce(_newValue, '');

    If _instrument <> '' Then
        SELECT instrument_id
        INTO _instrumentID
        FROM t_instrument_name
        WHERE instrument = _instrument;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

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
    )

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
        -- ToDo: Preview the table rows using RAISE INFO
        SELECT *
        FROM Tmp_InstrumentUsageInfo INNER JOIN
             t_emsl_instrument_usage_report TD ON Tmp_InstrumentUsageInfo.seq = TD.seq;

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

-- EvaluatePredefinedAnalysisRules was refactored into functions
--   predefined_analysis_jobs, predefined_analysis_rules, and get_predefined_analysis_rule_table and procedures
--   predefined_analysis_jobs_proc and predefined_analysis_rules_proc, and evaluate_predefined_analysis_rule
