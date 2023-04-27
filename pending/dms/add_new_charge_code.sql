--
CREATE OR REPLACE PROCEDURE public.add_new_charge_code
(
    _chargeCodeList text,
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a charge code (work package) to T_Charge_Code
**      Useful when a work package is not auto-adding to the table
**      (charge codes are auto-added if the owner is a DMS user or DMS guest)
**
**  Auth:   mem
**  Date:   08/13/2015 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _chargeCodeList := Coalesce(_chargeCodeList, '');
    _message := '';

    If _chargeCodeList = '' Then
        _message := '_chargeCodeList is empty; nothing to do';
        RAISE INFO '%', _message;
    Else
        Call update_charge_codes_from_warehouse (_infoOnly => _infoOnly, _updateAll => false, _onlyShowChanged => true, _explicitChargeCodeList => _ChargeCodeList, _message => _message);

        If _message <> '' Then
            RAISE INFO '%', _message;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_new_charge_code IS 'AddNewChargeCode';
