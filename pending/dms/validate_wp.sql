--
CREATE OR REPLACE PROCEDURE public.validate_wp
(
    _workPackage text,
    _allowNoneWP boolean,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Verifies that given work package exists in T_Charge_Code
**
**  Arguments:
**    _allowNoneWP   Set to true to allow _workPackage to be 'none'
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _workPackage := Coalesce(_workPackage, '');
    _allowNoneWP := Coalesce(_allowNoneWP, false);
    _message := '';
    _returnCode := '';

    If Coalesce(_workPackage, '') = '' Then
        _message := 'Work package cannot be blank';
        _returnCode := 'U5130';
        RETURN;
    End If;

    If _allowNoneWP And _workPackage = 'none' Then
        -- Allow the work package to be 'none'
    Else

        If _workPackage::citext IN ('none', 'na', 'n/a', '(none)') Then
            _message := 'A valid work package must be provided; see https://dms2.pnl.gov/helper_charge_code/report';
            _returnCode := 'U5131';
            RETURN;
        End If;

        If Not Exists (SELECT * FROM t_charge_code Where charge_code = _workPackage) Then
            _message := format('Could not find entry in database for Work Package "%s"; see https://dms2.pnl.gov/helper_charge_code/report', _workPackage);
            _returnCode := 'U5132';
            RETURN;
        End If;
    End If;
END
$$;

COMMENT ON PROCEDURE public.validate_wp IS 'ValidateWP';
