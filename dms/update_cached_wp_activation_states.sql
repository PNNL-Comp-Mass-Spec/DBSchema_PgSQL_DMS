CREATE OR REPLACE PROCEDURE public.update_cached_wp_activation_states(IN _workPackage text DEFAULT '', IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update cached work package activation states in table t_requested_run
**
**  Arguments:
**    _workPackage   Work package to update; if an empty string, update all requested runs
**    _showDebug     When true, show debug info
**    _message       Status message
**    _returnCode    Return code
**
**  Auth:   mem
**  Date:   05/17/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _requestedRunCount int;
    _updateCount int;
    _rowCountUpdated int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _workPackage := Trim(Coalesce(_workPackage, ''));
    _showDebug   := Coalesce(_showDebug, false);

    If _showDebug Then
        RAISE INFO '';
    End If;

    If _workPackage = '' Then
        ------------------------------------------------
        -- Update cached WP activation states for all requested runs
        ------------------------------------------------

        If _showDebug Then
            SELECT COUNT(request_id)
            INTO _requestedRunCount
            FROM t_requested_run;

            RAISE INFO 'Updating cached work package activation states for all % requested runs', _requestedRunCount;
        End If;

        -- Update cached WP activation states for all requested runs
        UPDATE t_requested_run RR
        SET cached_wp_activation_state = CC.activation_state
        FROM t_charge_code CC
        WHERE RR.work_package = CC.charge_code AND
              RR.cached_wp_activation_state <> CC.activation_state;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;
        _rowCountUpdated := _rowCountUpdated + _updateCount;

        -- Set cached WP activation state to 0 for requested runs that do not have a valid work package
        UPDATE t_requested_run
        SET cached_wp_activation_state = 0
        WHERE EXISTS (SELECT RR.request_id
                      FROM t_requested_run RR
                           LEFT OUTER JOIN t_charge_code CC
                             ON RR.work_package = CC.charge_code
                      WHERE CC.charge_code IS NULL AND
                            cached_wp_activation_state > 0 AND
                            t_requested_run.request_id = RR.request_id
                     );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;
        _rowCountUpdated := _rowCountUpdated + _updateCount;
    Else
        ------------------------------------------------
        -- Update cached WP activation states for one work package
        ------------------------------------------------

        If _showDebug Then
            If Not Exists (SELECT Charge_Code FROM T_Charge_Code WHERE Charge_Code = _workPackage::citext) Then
                RAISE WARNING 'Warning: Work package % does not exist', _workPackage;
            Else
                RAISE INFO 'Updating cached work package activation states for requested runs with work package %', _workPackage;
            End If;
        End If;

        -- Update cached WP activation states for one work package
        UPDATE t_requested_run RR
        SET cached_wp_activation_state = CC.activation_state
        FROM t_charge_code CC
        WHERE RR.work_package = _workPackage::citext AND
              RR.work_package = CC.charge_code AND
              RR.cached_wp_activation_state <> CC.activation_state;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;
        _rowCountUpdated := _rowCountUpdated + _updateCount;

    End If;

    If _rowCountUpdated > 0 Then
        _message = format('Updated %s %s in t_requested_run', _rowCountUpdated, public.check_plural(_rowCountUpdated, ' row', ' rows'));

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
    End If;

END
$$;
