--
CREATE OR REPLACE PROCEDURE public.lookup_other_from_experiment_sample_prep
(
    _experimentName text,
    INOUT _workPackage text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get values for misc fields from the sample prep
**      request associated with the given experiment (if there is one)
**
**      This procedure is used by AddUpdateRequestedRun and
**      the error messages assume that this is the case
**
**  Auth:   grk
**  Date:   06/03/2009 grk - Initial release (Ticket #499)
**          01/23/2017 mem - Provide clearer error messages
**          06/13/2017 mem - Fix failure to update _workPackage using sample prep request's work package
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _ovr text := '(lookup)';
    _prepRequestID int := 0;
    _newWorkPackage text;
BEGIN
    _message := '';
    _returnCode := '';

    _workPackage := Trim(_workPackage);

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------
    --
    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName;

    ---------------------------------------------------
    -- If there is no associated sample prep request we are done
    -- However, do not allow the workpackage to be (lookup)
    ---------------------------------------------------
    If Not FOUND Then
        If _workPackage = '' Or _workPackage = _ovr Then
            If Exists (SELECT * FROM t_experiments WHERE experiment = _experimentName) Then
                _message := format('Work package cannot be "%s" when the experiment does not have a sample prep request. Please provide a valid work package.', _ovr);
            Else
                _message := format('Unable to change the work package from "%s" to the one associated with the experiment because the experiment was not found: %s',
                                    _ovr, _experimentName
            End If;

            _returnCode := 'U5201';
            RETURN;
        Else
            RETURN;
        End If;
    End If;

    If _workPackage = '' Or _workPackage = _ovr Then
        ---------------------------------------------------
        -- Update the work package using the work package associated with the sample prep request
        ---------------------------------------------------

        SELECT Coalesce(work_package, '')
        INTO _newWorkPackage
        FROM t_sample_prep_request
        WHERE prep_request_id = _prepRequestID;

        _workPackage := _newWorkPackage;
    End If;

END
$$;

COMMENT ON PROCEDURE public.lookup_other_from_experiment_sample_prep IS 'LookupOtherFromExperimentSamplePrep';
