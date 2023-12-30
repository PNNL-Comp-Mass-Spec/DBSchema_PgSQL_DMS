--
-- Name: add_new_charge_code(text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_new_charge_code(IN _chargecodelist text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a charge code (work package) to t_charge_code
**
**      Useful when a work package is not auto-adding to the table
**      (charge codes are auto-added if the owner is a DMS user or DMS guest)
**
**  Arguments:
**    _chargeCodeList   Comma-separated list of charge codes (work packages) to add to t_charge_code
**    _infoOnly         When true, preview work package metadata that would be applied
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   08/13/2015 mem - Initial release
**          12/14/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _chargeCodeList := Trim(Coalesce(_chargeCodeList, ''));
    _infoOnly       := Coalesce(_infoOnly, false);

    If _chargeCodeList = '' Then
        _message := '_chargeCodeList is empty; nothing to do';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    CALL public.update_charge_codes_from_warehouse (
                    _infoOnly               => _infoOnly,
                    _updateAll              => false,
                    _onlyShowChanged        => false,
                    _explicitChargeCodeList => _chargeCodeList,
                    _message                => _message,        -- Output
                    _returnCode             => _returnCode);    -- Output

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.add_new_charge_code(IN _chargecodelist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_new_charge_code(IN _chargecodelist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_new_charge_code(IN _chargecodelist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AddNewChargeCode';

