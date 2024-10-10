--
-- Name: get_nearest_preceding_log_entry(integer, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _includetext boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the given item in t_emsl_instrument_usage_report
**
**      If the usage type is not 'Onsite' and the comment is empty,
**      look for the nearest preceeding log message in
**      t_instrument_operation_history and t_instrument_config_history
**
**  Arguments:
**    _seq              Item in t_emsl_instrument_usage_report to examine
**    _includeText      When true, include any extra text following the closing square bracket in the comment
**
**  Returns:
**      Nearest preceeding log message
**
**  Auth:   grk
**  Date:   08/28/2012
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/09/2024 mem - Prevent returning a message with an undefined operation history or config history ID
**                         - Trim trailing whitespace
**
*****************************************************/
DECLARE
    _usageInfo record;
    _opNote text;
    _opNoteTime timestamp;
    _opNoteID int;
    _opNoteFound boolean;
    _confNote text;
    _confNoteTime timestamp;
    _confNoteID int;
    _confNoteFound boolean;
    _message text;
BEGIN

    _includeText := Coalesce(_includeText, false);

    SELECT InstName.instrument,
           InstUsage.start,
           Coalesce(InstUsageType.usage_type, '') AS usage_type,
           InstUsage.comment
    INTO _usageInfo
    FROM t_emsl_instrument_usage_report InstUsage
         INNER JOIN t_instrument_name InstName
           ON InstUsage.dms_inst_id = InstName.instrument_id
         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
    WHERE InstUsage.seq = _seq;

    If _usageInfo.usage_type <> 'ONSITE' And Coalesce(_usageInfo.comment, '') = '' Then

        SELECT entry_id,
               entered,
               CASE WHEN _includeText
                    THEN Coalesce(note, '')
                    ELSE ''
               END
        INTO _opNoteID, _opNoteTime, _opNote
        FROM t_instrument_operation_history
        WHERE instrument = _usageInfo.instrument AND entered < _usageInfo.start
        ORDER BY entered DESC
        LIMIT 1;

        _opNoteFound := FOUND;

        SELECT entry_id,
               date_of_change ,
               CASE WHEN _includeText
                    THEN Coalesce(description, '')
                    ELSE ''
               END
        INTO _confNoteID, _confNoteTime, _confNote
        FROM t_instrument_config_history
        WHERE instrument = _usageInfo.instrument AND date_of_change < _usageInfo.start
        ORDER BY date_of_change DESC
        LIMIT 1;

        _confNoteFound := FOUND;

        If _opNoteFound And _confNoteFound Then
            _message := CASE WHEN _opNoteTime > _confNoteTime
                             THEN format('[Op Log:%s] %s',     _opNoteID,   _opNote)
                             ELSE format('[Config Log:%s] %s', _confNoteID, _confNote)
                        END;
        ElsIf _opNoteFound Then
            _message := format('[Op Log:%s] %s',     _opNoteID,   _opNote);
        ElsIf _confNoteFound Then
            _message := format('[Config Log:%s] %s', _confNoteID, _confNote);
        Else
            _message := '';
        End If;
    End If;

    RETURN Trim(Coalesce(_message, ''));
END
$$;


ALTER FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _includetext boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_nearest_preceding_log_entry(_seq integer, _includetext boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _includetext boolean) IS 'GetNearestPrecedingLogEntry';

