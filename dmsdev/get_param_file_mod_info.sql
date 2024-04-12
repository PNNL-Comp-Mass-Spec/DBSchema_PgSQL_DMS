--
-- Name: get_param_file_mod_info(text, integer, boolean, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_param_file_mod_info(IN _parameterfilename text, INOUT _paramfileid integer DEFAULT 0, INOUT _paramfilefound boolean DEFAULT false, INOUT _pmtargetsymbollist text DEFAULT ''::text, INOUT _pmmasscorrectiontaglist text DEFAULT ''::text, INOUT _npmasscorrectiontaglist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For a given parameter file, lookup potential dynamic and actual static modifications
**      and return a description of each as comma-separated lists
**
**      This procedure is likely unused in 2022
**
**  Arguments:
**    _parameterFileName        Name of parameter file
**    _paramFileID              Output: parameter file ID
**    _paramFileFound           Output: true if the parameter file exists in t_param_files
**    _pmTargetSymbolList       Output: comma-separated list of modification symbols
**    _pmMassCorrectionTagList  Output: comma-separated list of static and dynamic mod names (mass correction tags)
**    _npMassCorrectionTagList  Output: comma-separated list of isotopic mod names (mass correction tags)
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   07/24/2004 grk - Initial version
**          07/26/2004 mem - Added Order By Mod_ID
**          08/07/2004 mem - Added _paramFileFound parameter and updated references to use T_Seq_Local_Symbols_List
**          08/20/2004 grk - Major change to support consolidated mod description
**          08/22/2004 grk - Added _paramFileID
**          02/12/2010 mem - Increased size of _paramFileName to varchar(255)
**          04/02/2020 mem - Remove cast of Mass_Correction_Tag to varchar since no longer char(8)
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _targetSymbols text;
    _massCorrectionTags text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs and initialize the outputs
    -----------------------------------------------------------

    _parameterFileName       := Trim(Coalesce(_parameterFileName, ''));
    _pmTargetSymbolList      := '';
    _pmMassCorrectionTagList := '';
    _npMassCorrectionTagList := '';

    -----------------------------------------------------------
    -- Resolve parameter file name to ID
    -----------------------------------------------------------

    SELECT param_file_id
    INTO _paramFileID
    FROM t_param_files
    WHERE param_file_name = _parameterFileName::citext;

    If FOUND Then
        _paramFileFound := true;
    Else
        _paramFileID    := 0;
        _paramFileFound := false;
        _message := format('Unknown parameter file name: %s', _parameterFileName);
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Dynamic mods
    -----------------------------------------------------------

    SELECT string_agg(Local_Symbol,        ',' ORDER BY Local_Symbol),
           string_agg(Mass_Correction_Tag, ',' ORDER BY Local_Symbol)
    INTO _pmTargetSymbolList,
         _pmMassCorrectionTagList
    FROM ( SELECT Local_Symbol, Mass_Correction_Tag
           FROM V_Param_File_Mass_Mod_Info
           WHERE Mod_Type_Symbol = 'D' AND
                 Param_File_Name = _parameterFileName::citext
           GROUP BY Local_Symbol, Mass_Correction_Tag
         ) GroupQ;

    -----------------------------------------------------------
    -- Static mods and terminus mods
    -----------------------------------------------------------

    SELECT string_agg(Residue_Symbol,      ',' ORDER BY Residue_Symbol),
           string_agg(Mass_Correction_Tag, ',' ORDER BY Residue_Symbol)
    INTO _targetSymbols,
         _massCorrectionTags
    FROM V_Param_File_Mass_Mod_Info
    WHERE Mod_Type_Symbol IN ('T', 'P', 'S') AND
          Param_File_Name = _parameterFileName::citext;

    If _targetSymbols <> '' Then
        _pmTargetSymbolList := public.append_to_text(_pmTargetSymbolList, _targetSymbols, _delimiter => ',');
    End If;

    If _massCorrectionTags <> '' Then
        _pmMassCorrectionTagList := public.append_to_text(_pmMassCorrectionTagList, _massCorrectionTags, _delimiter => ',');
    End If;

    -----------------------------------------------------------
    -- Isotopic mods
    -----------------------------------------------------------

    SELECT string_agg(Mass_Correction_Tag, ',' ORDER BY Mass_Correction_Tag)
    INTO _npMassCorrectionTagList
    FROM V_Param_File_Mass_Mod_Info
    WHERE Mod_Type_Symbol IN ('I') AND
          Param_File_Name = _parameterFileName::citext;

    If _pmTargetSymbolList Is Null Then
        _pmTargetSymbolList := '';
    End If;

    If _pmMassCorrectionTagList Is Null Then
        _pmMassCorrectionTagList := '';
    End If;

    If _npMassCorrectionTagList Is Null Then
        _npMassCorrectionTagList := '';
    End If;
END
$$;


ALTER PROCEDURE public.get_param_file_mod_info(IN _parameterfilename text, INOUT _paramfileid integer, INOUT _paramfilefound boolean, INOUT _pmtargetsymbollist text, INOUT _pmmasscorrectiontaglist text, INOUT _npmasscorrectiontaglist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_param_file_mod_info(IN _parameterfilename text, INOUT _paramfileid integer, INOUT _paramfilefound boolean, INOUT _pmtargetsymbollist text, INOUT _pmmasscorrectiontaglist text, INOUT _npmasscorrectiontaglist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_param_file_mod_info(IN _parameterfilename text, INOUT _paramfileid integer, INOUT _paramfilefound boolean, INOUT _pmtargetsymbollist text, INOUT _pmmasscorrectiontaglist text, INOUT _npmasscorrectiontaglist text, INOUT _message text, INOUT _returncode text) IS 'GetParamFileModInfo';

