--
CREATE OR REPLACE PROCEDURE public.lookup_instrument_run_info_from_experiment_sample_prep
(
    _experimentName text,
    INOUT _instrumentGroup text,
    INOUT _datasetType text,
    INOUT _instrumentSettings text,
    INOUT _secSep text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get values for instrument related fields
**      from the sample prep request associated with
**      the given experiment (if there is one)
**
**  Auth:   grk
**  Date:   09/06/2007 (Ticket #512 http://prismtrac.pnl.gov/trac/ticket/512)
**          01/09/2012 grk - Added _secSep
**          03/28/2013 mem - Now returning more explicit error messages when the experiment does not have an associated sample prep request
**          06/10/2014 mem - Now using Instrument_Group in T_Sample_Prep_Request
**          08/20/2014 mem - Switched from Instrument_Name to Instrument_Group
**                         - Renamed parameter _instrumentName to _instrumentGroup
**          12/15/2023 mem - Ported to PostgreSQL
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
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName;

    ---------------------------------------------------
    -- If there is no associated sample prep request, we are done
    ---------------------------------------------------
    If Not FOUND Then
        If _instrumentGroup::citext = _ovr Then
            _message := format('Instrument group is set to "%s"; the experiment (%s) does not have a sample prep request, therefore we cannot auto-define the instrument group.',
                               _ovr, _experimentName);

            _returnCode := 'U5201';
            RETURN;
        End If;

        If _datasetType::citext = _ovr Then
            _message := format('Run Type (Dataset Type) is set to "%s"; the experiment (%s) does not have a sample prep request, therefore we cannot auto-define the run type.',
                               _ovr, _experimentName);

            _returnCode := 'U5202';
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

    SELECT
        COALESCE(instrument_group, instrument_name, '') As InstrumentGroup,
        Coalesce(dataset_type, '') As DatasetType,
        Coalesce(instrument_analysis_specifications, '') As InstrumentSettings,
        Coalesce(separation_type, '') As SeparationType
    INTO _instrumentInfo
    FROM t_sample_prep_request
    WHERE prep_request_id = _prepRequestID;

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------

    _instrumentGroup := CASE WHEN _instrumentGroup::citext = _ovr THEN _instrumentInfo.InstrumentGroup ELSE _instrumentGroup END;
    _datasetType := CASE WHEN _datasetType::citext = _ovr THEN _instrumentInfo.DatasetType ELSE _datasetType END;
    _instrumentSettings := CASE WHEN _instrumentSettings::citext = _ovr THEN _instrumentInfo.InstrumentSettings ELSE _instrumentSettings END;
    _secSep := CASE WHEN _secSep::citext = _ovr THEN _instrumentInfo.SeparationType ELSE _secSep END;

END
$$;

COMMENT ON PROCEDURE public.lookup_instrument_run_info_from_experiment_sample_prep IS 'LookupInstrumentRunInfoFromExperimentSamplePrep';
