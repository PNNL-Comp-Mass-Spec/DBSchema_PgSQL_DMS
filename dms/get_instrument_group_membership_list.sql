--
-- Name: get_instrument_group_membership_list(public.citext, integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_group_membership_list(_instrumentgroup public.citext, _activeonly integer, _maximumlength integer DEFAULT 64) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of associated instruments for given instrument group
**
**  Return value: delimited list, using a vertical bar if _activeOnly is 2, otherwise using a comma
**
**  Arguments:
**    _instrumentGroup  Instrument group name
**    _activeOnly       0 for all instruments, 1 for only active instruments, 2 to format the instruments as a vertical bar separated list of instrument name and ID (see comments below)
**    _maximumLength    Maximum length of the returned list of instruments; if 0, all instruments, sorted alphabetically
**
**  When _activeOnly is 2, the instrument list will be in the form:
**    InstrumentName:InstrumentID|InstrumentName:InstrumentID|InstrumentName:InstrumentID
**
**  Additionally, if the instrument is inactive or offsite, the instrument name will show that in parentheses, with inactive taking precedence
**  This is used to format instrument info on the Instrument Group Detail Report page, https://dms2.pnl.gov/instrument_group/show/VelosOrbi
**
**  Auth:   grk
**  Date:   08/30/2010 grk - Initial version
**          11/18/2019 mem - Add parameters _activeOnly and _maximumLength
**          02/18/2021 mem - Add _activeOnly=2 which formats the instruments as a vertical bar separated list of instrument name and instrument ID
**          06/21/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _result text := '';
    _delimiter VARCHAR(4);
BEGIN
    If _activeOnly = 2 Then
        _delimiter := '|';
    Else
        _delimiter := ', ';
    End If;

    If _maximumLength > 0 And _maximumLength < 10 Then
        _maximumLength := 10;
    End If;

    SELECT string_agg(
                format('%s%s%s%s',
                        instrument,
                        CASE WHEN _activeOnly = 2 AND status::citext = 'inactive'                                          THEN format(' (%s)', status)          ELSE '' END,
                        CASE WHEN _activeOnly = 2 AND status::citext <> 'inactive' AND operations_role::citext = 'Offsite' THEN format(' (%s)', operations_role) ELSE '' END,
                        CASE WHEN _activeOnly = 2                                                                          THEN format(':%s', instrument_id)     ELSE '' END
                      ),
                _delimiter ORDER BY instrument)
    INTO _result
    FROM t_instrument_name
    WHERE instrument_group = _instrumentGroup AND
            (_activeOnly In (0, 2) Or status <> 'inactive') AND
            (_activeOnly In (0, 2) Or operations_role <> 'Offsite');

    If _maximumLength > 0 And char_length(_result) > _maximumLength Then
        _result := Rtrim(Substring(_result, 1, _maximumLength - 3));

        If _result Like '%,' Then
            _result := format('%s ...', Substring(_result, 1, char_length(_result) - 1));
        Else
            _result := format('%s ...', _result);
        End If;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_instrument_group_membership_list(_instrumentgroup public.citext, _activeonly integer, _maximumlength integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_group_membership_list(_instrumentgroup public.citext, _activeonly integer, _maximumlength integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_group_membership_list(_instrumentgroup public.citext, _activeonly integer, _maximumlength integer) IS 'GetInstrumentGroupMembershipList';

