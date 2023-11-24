--
CREATE OR REPLACE PROCEDURE public.get_param_file_mod_info
(
    _parameterFileName text,
    INOUT _paramFileID int = 0,
    INOUT _paramFileFound boolean = false,
    INOUT _pmTargetSymbolList text = '',
    INOUT _pmMassCorrectionTagList text = '',
    INOUT _npMassCorrectionTagList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      For given analysis parameter file, look up potential dynamic and actual static modifications
**      and return description of each as comma-separated lists
**
**      This procedure is likely unused in 2022
**
**  Arguments:
**    _parameterFileName        Name of analysis parameter file
**    _paramFileID              Output: parameter file ID
**    _paramFileFound           Output: true if the parameter file exists in t_param_files
**    _pmTargetSymbolList       Output: comma separated list of modification symbols
**    _pmMassCorrectionTagList  Output: comma separated list of static and dynamic mod names (mass correction tags)
**    _npMassCorrectionTagList  Output: comma separated list of isotopic mod names (mass correction tags)
**    _message                  Output message
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _ln int;
BEGIN
    _message := '';
    _returnCode := '';

    _paramFileID := 0;
    _pmTargetSymbolList := '';
    _pmMassCorrectionTagList := '';
    _npMassCorrectionTagList := '';

    -----------------------------------------------------------
    -- Make sure this parameter file is defined in t_param_files
    -----------------------------------------------------------

    SELECT param_file_id
    INTO _paramFileID
    FROM t_param_files
    WHERE param_file_name = _parameterFileName;

    If FOUND Then
        _paramFileFound := true;
    Else
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
                 Param_File_Name = _parameterFileName
           GROUP BY Local_Symbol, Mass_Correction_Tag) GroupQ;

    -----------------------------------------------------------
    -- Static mods and terminus mods
    -----------------------------------------------------------

    SELECT string_agg(Residue_Symbol,      ',' ORDER BY Residue_Symbol),
           string_agg(Mass_Correction_Tag, ',' ORDER BY Residue_Symbol)
    INTO _pmTargetSymbolList,
         _pmMassCorrectionTagList
    FROM V_Param_File_Mass_Mod_Info
    WHERE Mod_Type_Symbol IN ('T', 'P', 'S') AND
          Param_File_Name = _parameterFileName;

    -----------------------------------------------------------
    -- Isotopic mods
    -----------------------------------------------------------

    SELECT string_agg(Mass_Correction_Tag, ',' ORDER BY Mass_Correction_Tag)
    INTO _npMassCorrectionTagList
    FROM V_Param_File_Mass_Mod_Info
    WHERE Mod_Type_Symbol IN ('I') AND
          Param_File_Name = _parameterFileName;

END
$$;

COMMENT ON PROCEDURE public.get_param_file_mod_info IS 'GetParamFileModInfo';
