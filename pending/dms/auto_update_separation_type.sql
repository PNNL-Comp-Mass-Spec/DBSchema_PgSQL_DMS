--
CREATE OR REPLACE PROCEDURE public.auto_update_separation_type
(
    _separationType text,
    _acqLengthMinutes int,
    INOUT _optimalSeparationType text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update the separation type based on the name and acquisition length
**
**  Auth:   mem
**  Date:   10/09/2020 mem - Initial version
**          10/10/2020 mem - Adjust threshold for LC-Dionex-Formic_30min
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
BEGIN

    _separationType := Coalesce(_separationType, '');
    _acqLengthMinutes := Coalesce(_acqLengthMinutes, 0);
    _optimalSeparationType := '';

    ---------------------------------------------------
    -- Update the separation type name if it matches certain conditions
    ---------------------------------------------------

    If _separationType Like 'LC-Waters-Formic%' AND _acqLengthMinutes > 5 Then
        If _acqLengthMinutes < 35 Then
            _optimalSeparationType := 'LC-Waters-Formic_30min';
        ElsIf _acqLengthMinutes < 48
            _optimalSeparationType := 'LC-Waters-Formic_40min';
        ElsIf _acqLengthMinutes < 80
            _optimalSeparationType := 'LC-Waters-Formic_60min';
        ElsIf _acqLengthMinutes < 107
            _optimalSeparationType := 'LC-Waters-Formic_90min';
        ElsIf _acqLengthMinutes < 165
            _optimalSeparationType := 'LC-Waters-Formic_2hr';
        ElsIf _acqLengthMinutes < 220
            _optimalSeparationType := 'LC-Waters-Formic_3hr';
        ElsIf _acqLengthMinutes < 280
            _optimalSeparationType := 'LC-Waters-Formic_4hr';
        Else
            _separationType := 'LC-Waters-Formic_5hr';
        End If;
    End If;

    If _separationType Like 'LC-Dionex-Formic%' AND _acqLengthMinutes > 5 Then
        If _acqLengthMinutes < 50 Then
           _optimalSeparationType := 'LC-Dionex-Formic_30min';
        ElsIf _acqLengthMinutes < 107
           _optimalSeparationType := 'LC-Dionex-Formic_100min';
        ElsIf _acqLengthMinutes < 165
           _optimalSeparationType := 'LC-Dionex-Formic_2hr';
        ElsIf _acqLengthMinutes < 280
           _optimalSeparationType := 'LC-Dionex-Formic_3hr';
        Else
           _optimalSeparationType := 'LC-Dionex-Formic_5hr';
        End If;
    End If;

    If _separationType Like 'LC-Agilent-Formic%' AND _acqLengthMinutes > 5 Then
        If _acqLengthMinutes < 35 Then
           _optimalSeparationType := 'LC-Agilent-Formic_30minute';
        ElsIf _acqLengthMinutes < 80
           _optimalSeparationType := 'LC-Agilent-Formic_60minute';
        ElsIf _acqLengthMinutes < 107
           _optimalSeparationType := 'LC-Agilent-Formic_100minute';
        ElsIf _acqLengthMinutes < 165
           _optimalSeparationType := 'LC-Agilent-Formic_2hr';
        Else
           _optimalSeparationType := 'LC-Agilent-Formic_3hr';
        End If;
    End If;

    If _optimalSeparationType <> '' Then
        -- Validate the auto-defined separation type
        If Not Exists (SELECT * from t_secondary_sep WHERE separation_type = _optimalSeparationType) Then
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

COMMENT ON PROCEDURE public.auto_update_separation_type IS 'AutoUpdateSeparationType';
