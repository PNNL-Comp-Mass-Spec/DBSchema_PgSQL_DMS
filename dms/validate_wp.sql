--
-- Name: validate_wp(text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_wp(IN _workpackage text, IN _allownonewp boolean, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Verify that the given work package exists in T_Charge_Code
**
**  Arguments:
**    _workPackage      Work package name
**    _allowNoneWP      Set to true to allow _workPackage to be 'none'
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          10/02/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning message
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    _workPackage := Trim(Coalesce(_workPackage, ''));
    _allowNoneWP := Coalesce(_allowNoneWP, false);

    If _workPackage = '' Then
        _message := 'Work package cannot be blank';
        _returnCode := 'U5130';
        RETURN;
    End If;

    If _allowNoneWP And Lower(_workPackage) = 'none' Then
        -- Allow the work package to be 'none'
        RETURN;
    End If;

    If _workPackage::citext In ('none', 'na', 'n/a', '(none)') Then
        _message := 'A valid work package must be specified; see https://dms2.pnl.gov/helper_charge_code/report';
        _returnCode := 'U5131';
        RETURN;
    End If;

    If Not Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackage::citext) Then
        _message := format('Work Package "%s" does not exist; see https://dms2.pnl.gov/helper_charge_code/report', _workPackage);
        _returnCode := 'U5132';
        RETURN;
    End If;
END
$$;


ALTER PROCEDURE public.validate_wp(IN _workpackage text, IN _allownonewp boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_wp(IN _workpackage text, IN _allownonewp boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_wp(IN _workpackage text, IN _allownonewp boolean, INOUT _message text, INOUT _returncode text) IS 'ValidateWP';

