--
CREATE OR REPLACE PROCEDURE public.add_mass_correction_entry
(
    _modName text,
    _modDescription text,
    _modMassChange float8,
    _modAffectedAtom text = '-',
    INOUT _message text = '',
    inout _returnCode text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new or updates an existing global modification
**
**  Auth:   kja
**  Date:   08/02/2004
**          10/17/2013 mem - Expanded _modDescription to varchar(128)
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          04/02/2020 mem - Expand _modName to varchar(32)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _massCorrectionID int := 0;
    _transName text;
BEGIN

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If char_length(_modName) < 1 Then
        _message := 'modName was blank';
        RAISE WARNING '%', _message;

        _returnCode := 'U5100';
        RETURN;
    End If;

    If char_length(_modDescription) < 1 Then
        _message := 'modDescription was blank';
        RAISE WARNING '%', _message;

        _returnCode := 'U5101';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    _massCorrectionID := get_mass_correction_id(_modMassChange);

    -- Cannot create an entry that already exists

    If _massCorrectionID <> 0 Then
        _msg := 'Cannot Add: Mass Correction "' || _modMasschange || '" already exists';
        RAISE WARNING '%', _msg;

        _returnCode := 'U5103';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If Exists ( SELECT mass_correction_id
                FROM t_mass_correction_factors
                WHERE mass_correction_tag = _modName::citext) Then
        _msg := 'Cannot Add: Mass Correction "' || _modName || '" already exists';
        RAISE WARNING '%', _msg;

        _returnCode := 'U5104';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddMassCorrectionFactor';
    begin transaction _transName

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    begin

        INSERT INTO t_mass_correction_factors (
            mass_correction_tag,
            description,
            monoisotopic_mass,
            affected_atom,
            original_source
        ) VALUES (
            _modName,
            _modDescription,
            Round(_modMassChange,4),
            _modAffectedAtom,
            'PNNL'
        )
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_mass_correction_entry IS 'AddMassCorrectionEntry';
