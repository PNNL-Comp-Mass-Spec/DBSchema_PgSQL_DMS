--
-- Name: lookup_wp_from_experiment_sample_prep(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.lookup_wp_from_experiment_sample_prep(IN _experimentname text, INOUT _workpackage text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Lookup the work package defined for the sample prep request associated with the given experiment (if there is one)
**
**      This procedure is used by add_update_requested_run and the error messages it returns assume that this is the case
**
**  Arguments:
**    _experimentName   Experiment name
**    _workPackage      Input/output: work package provided by the user; will be updated by this procedure if it is '' or '(lookup)' and the experiment has a sample prep request
**    _message          Error message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   06/03/2009 grk - Initial release (Ticket #499)
**          01/23/2017 mem - Provide clearer error messages
**          06/13/2017 mem - Fix failure to update _workPackage using sample prep request's work package
**          10/01/2023 mem - Ported to PostgreSQL (renamed from lookup_other_from_experiment_sample_prep to lookup_wp_from_experiment_sample_prep)
**          10/12/2023 mem - Use implicit string concatenation
**
*****************************************************/
DECLARE
    _ovr text := '(lookup)';
    _prepRequestID int;
    _newWorkPackage text;
BEGIN
    _message := '';
    _returnCode := '';

    _workPackage := Trim(Coalesce(_workPackage, ''));

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName::citext;

    ---------------------------------------------------
    -- If there is no associated sample prep request we are done
    -- However, do not allow the work package to be blank or '(lookup)'
    -- Note that experiments without a sample prep request will have sample_prep_request_id = 0
    ---------------------------------------------------

    If Not FOUND Or _prepRequestID = 0 Then
        If Not _workPackage IN ('', _ovr) Then
            RETURN;
        End If;

        If Exists (SELECT exp_id FROM t_experiments WHERE experiment = _experimentName::citext) Then
            _message := format('Work package cannot be "%s" when the experiment does not have a sample prep request. '
                               'Please provide a valid work package.', _ovr);
        Else
            _message := format('Unable to change the work package from "%s" to the one associated with the experiment '
                               'because the experiment was not found: %s', _ovr, _experimentName);
        End If;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _workPackage IN ('', _ovr) Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the work package using the work package associated with the sample prep request
    ---------------------------------------------------

    SELECT Trim(Coalesce(work_package, ''))
    INTO _newWorkPackage
    FROM t_sample_prep_request
    WHERE prep_request_id = _prepRequestID;

    _workPackage := _newWorkPackage;

END
$$;


ALTER PROCEDURE public.lookup_wp_from_experiment_sample_prep(IN _experimentname text, INOUT _workpackage text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE lookup_wp_from_experiment_sample_prep(IN _experimentname text, INOUT _workpackage text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.lookup_wp_from_experiment_sample_prep(IN _experimentname text, INOUT _workpackage text, INOUT _message text, INOUT _returncode text) IS 'LookupWPFromExperimentSamplePrep or LookupOtherFromExperimentSamplePrep';

