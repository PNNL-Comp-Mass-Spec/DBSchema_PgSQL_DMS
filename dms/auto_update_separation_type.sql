--
-- Name: auto_update_separation_type(text, integer, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_update_separation_type(IN _separationtype text, IN _acqlengthminutes integer, INOUT _optimalseparationtype text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the separation type based on the name and acquisition length
**
**      Ignores datasets with an acquisition length under 6 minutes
**
**  Arguments:
**     _separationType          Current separation type
**     _acqLengthMinutes        Acquisition length, in minutes
**     _optimalSeparationType   Output: optimal separation type to use
**
**  Auth:   mem
**  Date:   10/09/2020 mem - Initial version
**          10/10/2020 mem - Adjust threshold for LC-Dionex-Formic_30min
**          06/13/2023 mem - Exit the procedure if the acquisition length is <= 5 minutes
**                         - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _message text;
BEGIN

    _separationType        := Trim(Coalesce(_separationType, ''));
    _acqLengthMinutes      := Coalesce(_acqLengthMinutes, 0);
    _optimalSeparationType := '';

    If _acqLengthMinutes <= 5 Then
        If _acqLengthMinutes <= 0 Then
            RAISE INFO 'Acquisition length is 0 minutes; not updating separation type';
        Else
            RAISE INFO 'Acquisition length is less than 5 minutes; not updating separation type';
        End If;

        _optimalSeparationType := _separationType;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the separation type name if it matches certain conditions
    ---------------------------------------------------

    If _separationType Like 'LC-Waters-Formic%' Then
        If _acqLengthMinutes < 35 Then
            _optimalSeparationType := 'LC-Waters-Formic_30min';
        ElsIf _acqLengthMinutes < 48 Then
            _optimalSeparationType := 'LC-Waters-Formic_40min';
        ElsIf _acqLengthMinutes < 80 Then
            _optimalSeparationType := 'LC-Waters-Formic_60min';
        ElsIf _acqLengthMinutes < 107 Then
            _optimalSeparationType := 'LC-Waters-Formic_90min';
        ElsIf _acqLengthMinutes < 165 Then
            _optimalSeparationType := 'LC-Waters-Formic_2hr';
        ElsIf _acqLengthMinutes < 220 Then
            _optimalSeparationType := 'LC-Waters-Formic_3hr';
        ElsIf _acqLengthMinutes < 280 Then
            _optimalSeparationType := 'LC-Waters-Formic_4hr';
        Else
            _separationType := 'LC-Waters-Formic_5hr';
        End If;
    End If;

    If _separationType Like 'LC-Dionex-Formic%' Then
        If _acqLengthMinutes < 50 Then
           _optimalSeparationType := 'LC-Dionex-Formic_30min';
        ElsIf _acqLengthMinutes < 107 Then
           _optimalSeparationType := 'LC-Dionex-Formic_100min';
        ElsIf _acqLengthMinutes < 165 Then
           _optimalSeparationType := 'LC-Dionex-Formic_2hr';
        ElsIf _acqLengthMinutes < 280 Then
           _optimalSeparationType := 'LC-Dionex-Formic_3hr';
        Else
           _optimalSeparationType := 'LC-Dionex-Formic_5hr';
        End If;
    End If;

    If _separationType Like 'LC-Agilent-Formic%' Then
        If _acqLengthMinutes < 35 Then
           _optimalSeparationType := 'LC-Agilent-Formic_30minute';
        ElsIf _acqLengthMinutes < 80 Then
           _optimalSeparationType := 'LC-Agilent-Formic_60minute';
        ElsIf _acqLengthMinutes < 107 Then
           _optimalSeparationType := 'LC-Agilent-Formic_100minute';
        ElsIf _acqLengthMinutes < 165 Then
           _optimalSeparationType := 'LC-Agilent-Formic_2hr';
        Else
           _optimalSeparationType := 'LC-Agilent-Formic_3hr';
        End If;
    End If;

    If _optimalSeparationType <> '' Then
        -- Validate the auto-defined separation type
        If Not Exists (SELECT separation_type_id FROM t_secondary_sep WHERE separation_type = _optimalSeparationType) Then
            _message := format('Invalid separation type; %s not found in t_secondary_sep', _optimalSeparationType);

            CALL post_log_entry ('Error', _message, 'Auto_Update_Separation_Type', _duplicateEntryHoldoffHours => 1);

            _optimalSeparationType := '';
        End If;
    End If;

    If _optimalSeparationType = '' Then
        _optimalSeparationType := _separationType;
    End If;

END
$$;


ALTER PROCEDURE public.auto_update_separation_type(IN _separationtype text, IN _acqlengthminutes integer, INOUT _optimalseparationtype text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_update_separation_type(IN _separationtype text, IN _acqlengthminutes integer, INOUT _optimalseparationtype text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_update_separation_type(IN _separationtype text, IN _acqlengthminutes integer, INOUT _optimalseparationtype text) IS 'AutoUpdateSeparationType';

