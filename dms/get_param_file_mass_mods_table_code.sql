--
-- Name: get_param_file_mass_mods_table_code(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the mass mods for the given parameter file, formatted as a string-based table
**      The format codes are thosed used by Jira
**
**  Arguments:
**    _paramFileId      Parameter file ID
**
**  Returns:
**      List of mass mods delimited by '<br>'
**
**  Auth:   mem
**  Date:   12/05/2016 mem - Initial version
**          06/22/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Use format() for string concatenation
**          09/27/2024 mem - Use view v_param_file_mass_mods_padded
**
*****************************************************/
DECLARE
    _header text;
    _list text;
    _result text;
BEGIN

    SELECT Replace(table_code_header, ' ', '&nbsp;'),
           string_agg(Replace(table_code_row, ' ', '&nbsp;'), '<br>' ORDER BY table_code_row)
    INTO _header, _list
    FROM v_param_file_mass_mods_padded
    WHERE param_file_id = _paramFileId
    GROUP BY table_code_header;

    If FOUND Then
        _result := format('%s<br>%s', _header, _list);
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_param_file_mass_mods_table_code(_paramfileid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) IS 'GetParamFileMassModsTableCode';

