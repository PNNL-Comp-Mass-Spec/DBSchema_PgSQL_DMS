--
-- Name: get_param_file_mass_mods_table_code(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the mass mods for the given parameter file, formatted as a string-based table
**      The format codes are thosed used by Jira
**
**  Return value: list of mass mods delimited by '<br>'
**
**  Auth:   mem
**  Date:   12/05/2016 mem - Initial version
**          06/22/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _header text;
    _list text;
    _result text;
BEGIN

    SELECT Table_Code_Header,
           string_agg(Table_Code_Row, '<br>' ORDER BY Table_Code_Row)
    INTO _header, _list
    FROM V_Param_File_Mass_Mods
    WHERE Param_File_ID = _paramFileId
    GROUP BY Table_Code_Header;

    If Found Then
        _result := _header || '<br>' || _list;
    End If;

    Return Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_param_file_mass_mods_table_code(_paramfileid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_param_file_mass_mods_table_code(_paramfileid integer) IS 'GetParamFileMassModsTableCode';

