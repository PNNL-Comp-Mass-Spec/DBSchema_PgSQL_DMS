--
-- Name: get_maxquant_mass_mods_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_maxquant_mass_mods_list(_paramfileid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of Mod names and IDs for the given MaxQuant parameter file
**
**  Return value: list of mass mods, delimited by vertical bars and colons
**
**  Auth:   mem
**  Date:   03/05/2021 mem - Initial version
**          06/22/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _result text;
BEGIN
    SELECT string_agg(LookupQ.ModInfo, '|' ORDER BY LookupQ.mod_type_symbol DESC, LookupQ.mod_title)
    INTO _list
    FROM ( SELECT MQM.mod_title || ':' || MQM.mod_id::text || ':' ||
                     CASE PFMM.Mod_Type_Symbol
                         WHEN 'S' THEN 'Static'
                         WHEN 'D' THEN 'Dynamic'
                         WHEN 'T' THEN 'Static Terminal Peptide'
                         WHEN 'P' THEN 'Static Terminal Protein'
                         WHEN 'I' THEN 'Isotopic'
                         ELSE PFMM.Mod_Type_Symbol
                     END ||
                     ':' || R.Residue_Symbol || ':' ||
                     Round(MCF.Monoisotopic_Mass::numeric, 4)::text AS ModInfo,
                  PFMM.mod_type_symbol,
                  MQM.mod_title
           FROM t_param_file_mass_mods PFMM
                INNER JOIN t_residues R
                  ON PFMM.residue_id = R.residue_id
                INNER JOIN t_mass_correction_factors MCF
                  ON PFMM.mass_correction_id = MCF.mass_correction_id
                INNER JOIN t_seq_local_symbols_list SLS
                  ON PFMM.local_symbol_id = SLS.local_symbol_id
                INNER JOIN t_param_files PF
                  ON PFMM.param_file_id = PF.param_file_id
                INNER JOIN t_maxquant_mods MQM
                  ON MQM.mod_id = PFMM.maxquant_mod_id
           WHERE PF.param_file_id = _paramFileId
         ) LookupQ;

    If Coalesce(_list ,'') = '' Then
        _result := '';
    Else
        _result := '!Headers!Name:Mod_ID:Type:Residue:Mass|' || _list;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_maxquant_mass_mods_list(_paramfileid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_maxquant_mass_mods_list(_paramfileid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_maxquant_mass_mods_list(_paramfileid integer) IS 'GetMaxQuantMassModsList';

