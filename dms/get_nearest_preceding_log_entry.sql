--
-- Name: get_nearest_preceding_log_entry(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _omittext integer DEFAULT 0) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Examines the given item in t_emsl_instrument_usage_report
**
**          If the usage type is not 'Onsite' and the comment is empty,
**          looks for the nearest preceeding log message in
**          t_instrument_operation_history and t_instrument_config_history
**
**  Return value: nearest preceeding log message
**
**  Auth:   grk
**  Date:   08/28/2012
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _usageInfo record;
    _opNote text;
    _opNoteTime timestamp;
    _opNoteID int;
    _confNote text;
    _confNoteTime timestamp;
    _confNoteID int;
    _message text;
BEGIN
    SELECT InstName.instrument,
           InstUsage.start,
           Coalesce(InstUsageType.usage_type, '') as usage_type,
           InstUsage.comment
    INTO _usageInfo
    FROM t_emsl_instrument_usage_report InstUsage
         INNER JOIN t_instrument_name InstName
           ON InstUsage.dms_inst_id = InstName.instrument_id
         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
    WHERE InstUsage.seq = _seq;

    If _usageInfo.usage_type <> 'ONSITE' AND Coalesce(_usageInfo.comment, '') = '' Then

        SELECT entry_id,
               entered,
               CASE WHEN _omitText > 0 THEN Coalesce(note, '') ELSE '' END
        INTO _opNoteID, _opNoteTime, _opNote
        FROM t_instrument_operation_history
        WHERE instrument = _usageInfo.instrument AND entered < _usageInfo.start
        ORDER BY entered DESC
        LIMIT 1;

        SELECT entry_id,
               date_of_change ,
               CASE WHEN _omitText > 0 THEN Coalesce(description, '') ELSE '' END
        INTO _confNoteID, _confNoteTime, _confNote
        FROM t_instrument_config_history
        WHERE instrument = _usageInfo.instrument AND date_of_change < _usageInfo.start
        ORDER BY date_of_change DESC
        LIMIT 1;

       _message := CASE WHEN _opNoteTime > _confNoteTime
                        THEN '[Op Log:'     || _opNoteID::text   || '] ' || _opNote
                        ELSE '[Config Log:' || _confNoteID::text || '] ' || _confNote
                      End If;
    End If;

    RETURN Coalesce(_message, '');
END
$$;


ALTER FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _omittext integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_nearest_preceding_log_entry(_seq integer, _omittext integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_nearest_preceding_log_entry(_seq integer, _omittext integer) IS 'GetNearestPrecedingLogEntry';

