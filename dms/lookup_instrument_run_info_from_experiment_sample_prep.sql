--
-- Name: lookup_instrument_run_info_from_experiment_sample_prep(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.lookup_instrument_run_info_from_experiment_sample_prep(IN _experimentname text, INOUT _instrumentgroup text DEFAULT ''::text, INOUT _datasettype text DEFAULT ''::text, INOUT _instrumentsettings text DEFAULT ''::text, INOUT _separationgroup text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get values for instrument related fields from the sample prep request associated with the given experiment (if there is one)
**
**  Arguments:
**    _experimentName       Experiment name
**    _instrumentGroup      Input/output: Instrument group;    if this is '(lookup)', will override with the instrument info from the sample prep request (if found)
**    _datasetType          Input/output: Dataset type;        if this is '(lookup)', will override with the instrument info from the sample prep request (if found)
**    _instrumentSettings   Input/output: Instrument settings; if this is '(lookup)', will be set to 'na'
**    _separationGroup      Input/Output: LC separation group
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   09/06/2007 grk - Ticket #512 (http://prismtrac.pnl.gov/trac/ticket/512)
**          01/09/2012 grk - Added _secSep
**          03/28/2013 mem - Now returning more explicit error messages when the experiment does not have an associated sample prep request
**          06/10/2014 mem - Now using Instrument_Group in T_Sample_Prep_Request
**          08/20/2014 mem - Switch from Instrument_Name to Instrument_Group
**                         - Rename parameter _instrumentName to _instrumentGroup
**          09/13/2023 mem - Ported to PostgreSQL
**          10/09/2023 mem - Rename parameter _secSep to _separationGroup
**          10/10/2023 mem - Use renamed column name separation_group in t_sample_prep_request
**          08/08/2024 mem - Cast experiment name to citext when querying t_experiments
**
*****************************************************/
DECLARE
    _instrumentInfo record;
    _ovr citext := '(lookup)';
    _prepRequestID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _experimentName     := Trim(Coalesce(_experimentName, ''));
    _instrumentGroup    := Trim(Coalesce(_instrumentGroup, ''));
    _datasetType        := Trim(Coalesce(_datasetType, ''));
    _instrumentSettings := Trim(Coalesce(_instrumentSettings, ''));
    _separationGroup    := Trim(Coalesce(_separationGroup, ''));

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName::citext;

    If Not FOUND Then
        _message := format('Experiment does not exist: %s',_experimentName);

        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Coalesce(_prepRequestID, 0) = 0 Then
        If _instrumentGroup::citext = _ovr Then
            _message := format('Instrument group is set to "%s"; the experiment (%s) does not have a sample prep request, therefore we cannot auto-define the instrument group',
                               _ovr, _experimentName);

            RAISE WARNING '%', _message;
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _datasetType::citext = _ovr Then
            _message := format('Run Type (dataset type) is set to "%s"; the experiment (%s) does not have a sample prep request, therefore we cannot auto-define the run type',
                               _ovr, _experimentName);

            RAISE WARNING '%', _message;
            _returnCode := 'U5203';
            RETURN;
        End If;

        If _instrumentSettings::citext = _ovr Then
            _instrumentSettings := 'na';
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup instrument fields from sample prep request
    ---------------------------------------------------

    SELECT COALESCE(instrument_group, instrument_name, '') AS InstrumentGroup,
           COALESCE(dataset_type, '') AS DatasetType,
           COALESCE(instrument_analysis_specifications, '') AS InstrumentSettings,
           COALESCE(separation_group, '') AS SeparationGroup
    INTO _instrumentInfo
    FROM t_sample_prep_request
    WHERE prep_request_id = _prepRequestID;

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------

    _instrumentGroup    := CASE WHEN _instrumentGroup::citext    = _ovr THEN _instrumentInfo.InstrumentGroup    ELSE _instrumentGroup END;
    _datasetType        := CASE WHEN _datasetType::citext        = _ovr THEN _instrumentInfo.DatasetType        ELSE _datasetType END;
    _instrumentSettings := CASE WHEN _instrumentSettings::citext = _ovr THEN _instrumentInfo.InstrumentSettings ELSE _instrumentSettings END;
    _separationGroup    := CASE WHEN _separationGroup::citext    = _ovr THEN _instrumentInfo.SeparationGroup    ELSE _separationGroup END;

END
$$;


ALTER PROCEDURE public.lookup_instrument_run_info_from_experiment_sample_prep(IN _experimentname text, INOUT _instrumentgroup text, INOUT _datasettype text, INOUT _instrumentsettings text, INOUT _separationgroup text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE lookup_instrument_run_info_from_experiment_sample_prep(IN _experimentname text, INOUT _instrumentgroup text, INOUT _datasettype text, INOUT _instrumentsettings text, INOUT _separationgroup text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.lookup_instrument_run_info_from_experiment_sample_prep(IN _experimentname text, INOUT _instrumentgroup text, INOUT _datasettype text, INOUT _instrumentsettings text, INOUT _separationgroup text, INOUT _message text, INOUT _returncode text) IS 'LookupInstrumentRunInfoFromExperimentSamplePrep';

