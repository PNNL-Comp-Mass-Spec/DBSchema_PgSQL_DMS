--
-- Name: get_param_file_mass_mod_code_list(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_param_file_mass_mod_code_list(_paramfileid integer, _includesymbol integer DEFAULT 0) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the mass mods for the given parameter file,
**      formatted as a comma-separated list of mod codes
**
**  Auth:   mem
**  Date:   11/04/2021 mem - Initial version
**          06/22/2022 mem - Ported to PostgreSQL
**          07/22/2022 mem - Change the delimiter to a comma
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    If _includeSymbol > 0 Then
        SELECT string_agg(Mod_Code_With_Symbol, ', ' ORDER BY Mod_Code_With_Symbol)
        INTO _result
        FROM V_Param_File_Mass_Mod_Info
        WHERE Param_File_ID = _paramFileId;
    Else
        SELECT string_agg(Mod_Code, ', ' ORDER BY Mod_Code)
        INTO _result
        FROM V_Param_File_Mass_Mod_Info
        WHERE Param_File_ID = _paramFileId;
    End If;

    Return Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_param_file_mass_mod_code_list(_paramfileid integer, _includesymbol integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_param_file_mass_mod_code_list(_paramfileid integer, _includesymbol integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_param_file_mass_mod_code_list(_paramfileid integer, _includesymbol integer) IS 'GetParamFileMassModCodeList';

