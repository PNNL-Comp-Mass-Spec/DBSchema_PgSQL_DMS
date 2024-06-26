--
-- Name: add_mass_correction_entry(text, text, double precision, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_mass_correction_entry(IN _modname text, IN _moddescription text, IN _modmasschange double precision, IN _modaffectedatom text DEFAULT '-'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new post translational modification to t_mass_correction_factors
**
**  Arguments:
**    _modName          Modification name
**    _modDescription   Modification description
**    _modMassChange    Modification mass
**    _modAffectedAtom  Affected atom (for isotopic mods on N, C, H, O, etc.); use '-' if not an isotopic modification
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   08/02/2004
**          10/17/2013 mem - Expanded _modDescription to varchar(128)
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          04/02/2020 mem - Expand _modName to varchar(32)
**          08/27/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Update warning messages
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
**          01/03/2024 mem - Update warning messages
**          01/11/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _msg text;
    _massCorrectionID int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _modName         := Trim(Coalesce(_modName, ''));
    _modDescription  := Trim(Coalesce(_modDescription, ''));
    _modMassChange   := Coalesce(_modMassChange, 0);
    _modAffectedAtom := Trim(Coalesce(_modAffectedAtom, '-'));

    If _modName = '' Then
        _message := 'Modification name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _modDescription = '' Then
        _message := 'Modification description must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _modMassChange = 0 Then
        _message := 'Mod mass cannot be zero';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is mod mass already in database?
    ---------------------------------------------------

    _massCorrectionID := public.get_mass_correction_id(_modMassChange);

    -- Cannot create an entry that already exists
    -- Look for existing modifications with a mass within 0.00006 Da of _modMassChange

    If _massCorrectionID <> 0 Then
        _msg := format('Cannot add: mass correction "%s" already exists', _modMassChange);
        RAISE WARNING '%', _msg;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If Exists (SELECT mass_correction_id
               FROM t_mass_correction_factors
               WHERE mass_correction_tag = _modName::citext)
    Then
        _msg := format('Cannot add: mass Correction "%s" already exists', _modName);
        RAISE WARNING '%', _msg;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO t_mass_correction_factors (
        mass_correction_tag,
        description,
        monoisotopic_mass,
        affected_atom,
        original_source
    ) VALUES (
        _modName,
        _modDescription,
        Round(_modMassChange::numeric, 6),
        _modAffectedAtom,
        'PNNL'
    );

END
$$;


ALTER PROCEDURE public.add_mass_correction_entry(IN _modname text, IN _moddescription text, IN _modmasschange double precision, IN _modaffectedatom text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_mass_correction_entry(IN _modname text, IN _moddescription text, IN _modmasschange double precision, IN _modaffectedatom text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_mass_correction_entry(IN _modname text, IN _moddescription text, IN _modmasschange double precision, IN _modaffectedatom text, INOUT _message text, INOUT _returncode text) IS 'AddMassCorrectionEntry';

