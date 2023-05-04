--
CREATE OR REPLACE PROCEDURE public.add_requested_runs
(
    _experimentGroupID text = '',
    _experimentList text = '',
    _requestNameSuffix text = '',
    _operatorUsername text,
    _instrumentGroup text,
    _workPackage text,
    _msType text,
    _instrumentSettings text = 'na',
    _eusProposalID text = 'na',
    _eusUsageType text,
    _eusUsersList text = '',
    _internalStandard text = 'na',
    _comment text = 'na',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _separationGroup text = 'LC-Formic_100min',
    _mrmAttachment text,
    _vialingConc text = null,
    _vialingVol text = null,
    _stagingLocation text = null,
    _batchName text = '',
    _batchDescription text = '',
    _batchCompletionDate text = '',
    _batchPriority text = '',
    _batchPriorityJustification text,
    _batchComment text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a group of entries to the requested run table
**
**  Arguments:
**    _experimentGroupID   Specify ExperimentGroupID or ExperimentList, but not both
**    _requestNameSuffix   Actually used as the request name Suffix
**    _instrumentGroup     Instrument group; could also contain '(lookup)'
**    _workPackage         Work Package; could also contain '(lookup)'
**    _msType              Run type; could also contain '(lookup)'
**    _eusUsersList        Comma separated list of EUS user IDs (integers); also supports the form 'Baker, Erin (41136)'
**    _mode                'add' or 'PreviewAdd'
**    _separationGroup     Separation group; could also contain '(lookup)'
**    _batchName           If defined, create a new batch for the newly created requested runs
**
**  Auth:   grk
**  Date:   07/22/2005 - Initial version
**          07/27/2005 grk - modified prefix
**          10/12/2005 grk - Added stuff for new work package and proposal fields.
**          02/23/2006 grk - Added stuff for EUS proposal and user tracking.
**          03/24/2006 grk - Added stuff for auto incrementing well numbers.
**          06/23/2006 grk - Removed instrument name from generated request name
**          10/12/2006 grk - Fixed trailing suffix in name (Ticket #248)
**          11/09/2006 grk - Fixed error message handling (Ticket #318)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          09/06/2007 grk - Removed _specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          04/25/2008 grk - Added secondary separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          07/27/2009 grk - removed autonumber for well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          03/02/2010 grk - added status field to requested run
**          08/27/2010 mem - Now referring to _instrumentGroup as an instrument group
**          09/29/2011 grk - fixed limited size of variable holding delimited list of experiments from group
**          12/14/2011 mem - Added parameter _callingUser, which is passed to AddUpdateRequestedRun
**          02/20/2012 mem - Now using a temporary table to track the experiment names for which requested runs need to be created
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          06/13/2013 mem - Added _vialingConc and _vialingVol
                           - Now validating _workPackageNumber against T_Charge_Code
**          06/18/2014 mem - Now passing default to udfParseDelimitedList
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling AddUpdateRequestedRun
**          12/12/2017 mem - Add _stagingLocation (points to T_Material_Locations)
**          05/29/2021 mem - Add parameters to allow also creating a batch
**          06/01/2021 mem - Show names of the new requests when previewing updates
**          07/01/2021 mem - Rename instrument parameter to be _instrumentGroup
**                         - Add parameters _batchPriorityJustification and _batchComment
**          07/09/2021 mem - Fix bug handling instrument group name when _batchName is blank
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/17/2022 mem - Update operator username warning
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling AddUpdateRequestedRun
**          11/25/2022 mem - Update call to AddUpdateRequestedRun to use new parameter name
**          02/14/2023 mem - Use new parameter names for validate_requested_run_batch_params
**          02/17/2023 mem - Use new parameter name when calling AddUpdateRequestedRunBatch
**          02/27/2023 mem - Use new argument name, _requestName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text := '';
    _logErrors boolean := false;
    _experimentGroupIDVal int;
    _allowNoneWP boolean := false;
    _locationID int := null;
    _wellplateName text := '(lookup)';
    _wellNumber text := '(lookup)';
    _instrumentGroupToUse text;
    _userID int;
    _requestName text;
    _requestNameFirst text := '';
    _requestNameLast text := '';
    _request int;
    _experimentName text;
    _suffix text := Coalesce(@requestNameSuffix, '');
    _count int := 0;
    _entryID int := 0;
    _requestedRunList text := '';
    _requestedRunMode text;
    _resolvedInstrumentInfo text := '';
    _resolvedInstrumentInfoCurrent text := '';
    _batchID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        _experimentGroupID := Trim(Coalesce(_experimentGroupID, ''));
        _experimentList := Trim(Coalesce(_experimentList, ''));
        _batchName := Trim(Coalesce(_batchName, ''));

        If _experimentGroupID <> '' AND _experimentList <> '' Then
            _returnCode := 'U5130';
            _message := 'Experiment Group ID and Experiment List cannot both be non-blank';
            RAISE EXCEPTION '%', _message;
        End If;
        --
        If _experimentGroupID = '' AND _experimentList = '' Then
            _returnCode := 'U5131';
            _message := 'Experiment Group ID and Experiment List cannot both be blank';
            RAISE EXCEPTION '%', _message;
        End If;
        --

        If char_length(_experimentGroupID) > 0 Then
            _experimentGroupIDVal := public.try_cast(_experimentGroupID, null::int);

            If _experimentGroupIDVal Is Null Then
                _returnCode := 'U5132';
                _message := 'Experiment Group ID must be a number: ' || _experimentGroupID;
                RAISE EXCEPTION '%', _message;
            End If;
        End If;
        --
        If char_length(_operatorUsername) < 1 Then
            _returnCode := 'U5113';
            RAISE EXCEPTION 'Operator username was blank';
        End If;
        --
        If char_length(_instrumentGroup) < 1 Then
            _returnCode := 'U5114';
            RAISE EXCEPTION 'Instrument group was blank';
        End If;
        --
        If char_length(_msType) < 1 Then
            _returnCode := 'U5115';
            RAISE EXCEPTION 'Dataset type was blank';
        End If;
        --
        If char_length(_workPackage) < 1 Then
            _returnCode := 'U5116';
            RAISE EXCEPTION 'Work package was blank';
        End If;
        --
        If _returnCode <> '' Then
            RETURN;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        -- Validation checks are complete; now enable _logErrors
        _logErrors := true;

        ---------------------------------------------------
        -- Validate the work package
        -- This validation also occurs in AddUpdateRequestedRun but we want to validate it now before we enter the while loop
        ---------------------------------------------------

        If _workPackage <> '(lookup)' Then
            Call validate_wp ( _workPackageNumber,
                               _allowNoneWP,
                               _message => _msg,
                               _returnCode => _returnCode);

            If _returnCode <> '' Then
                RAISE EXCEPTION 'ValidateWP: %', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve staging location name to location ID
        ---------------------------------------------------

        If Coalesce(_stagingLocation, '') <> '' Then
            SELECT location_id
            INTO _locationID
            FROM t_material_locations
            WHERE location = _stagingLocation;

            If Not FOUND Then
                RAISE EXCEPTION 'Staging location not recognized';
            End If;

        End If;

        ---------------------------------------------------
        -- Populate a temporary table with the experiments to process
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_ExperimentsToProcess
        (
            EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Experiment text,
            RequestID Int null
        )

        If _experimentGroupID <> '' Then
            ---------------------------------------------------
            -- Determine experiment names using experiment group ID
            ---------------------------------------------------

            INSERT INTO Tmp_ExperimentsToProcess (experiment)
            SELECT t_experiments.experiment
            FROM t_experiments
                 INNER JOIN t_experiment_group_members
                   ON t_experiments.exp_id = t_experiment_group_members.exp_id
                 LEFT OUTER JOIN t_experiment_groups
                   ON t_experiments.exp_id <> t_experiment_groups.parent_exp_id
                      AND
                      t_experiment_group_members.group_id = t_experiment_groups.group_id
            WHERE (t_experiment_groups.group_id = _experimentGroupIDVal)
            ORDER BY t_experiments.experiment
        Else
            ---------------------------------------------------
            -- Parse _experimentList to determine experiment names
            ---------------------------------------------------

            INSERT INTO Tmp_ExperimentsToProcess (Experiment)
            SELECT Value
            FROM public.parse_delimited_list(_experimentList)
            WHERE char_length(Value) > 0
            ORDER BY Value
        End If;

        ---------------------------------------------------
        -- Set up wellplate stuff to force lookup
        -- from experiments
        ---------------------------------------------------
        --

        If char_length(_batchName) > 0 Then
            ---------------------------------------------------
            -- Validate batch fields
            ---------------------------------------------------

            Call validate_requested_run_batch_params (
                    _batchID => 0,
                    _name => _batchName,
                    _description => _batchDescription,
                    _ownerUsername => _operatorUsername,
                    _requestedBatchPriority => _batchPriority,
                    _requestedCompletionDate => _batchCompletionDate,
                    _justificationHighPriority => _batchPriorityJustification,
                    _requestedInstrumentGroup => _instrumentGroup,              -- Will typically contain an instrument group, not an instrument name
                    _comment => _batchComment,
                    _mode => _mode,
                    _instrumentGroupToUse => _instrumentGroupToUse, -- Output
                    _userID => _userID,                             -- Output
                    _message => _message,                           -- Output
                    _returnCode => _returnCode);                    -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _message;
            End If;
        Else
            _instrumentGroupToUse := _instrumentGroup;
        End If;

        ---------------------------------------------------
        -- Step through experiments in Tmp_ExperimentsToProcess and make
        -- a new requested run for each one
        ---------------------------------------------------

        If _suffix <> '' Then
            _suffix := '_' || _suffix;
        End If;

        If _mode::citext = 'PreviewAdd' Then
            _requestedRunMode := 'check_add';
        Else
            _requestedRunMode := 'add';
        End If;

        FOR _entryID, _experimentName IN
            SELECT EntryID, Experiment
            FROM Tmp_ExperimentsToProcess
            ORDER BY EntryID
        LOOP
            _message := '';
            _requestName := _experimentName + _suffix;

            If _count = 0 Then
                _requestNameFirst := _requestName;
            Else
                _requestNameLast := _requestName;
            End If;

            Call dbo.add_update_requested_run (
                                    _requestName => _requestName,
                                    _experimentName => _experimentName,
                                    _requesterUsername => _operatorUsername,
                                    _instrumentName => _instrumentGroupToUse,
                                    _workPackage => _workPackage,
                                    _msType => _msType,
                                    _instrumentSettings => _instrumentSettings,
                                    _wellplateName => _wellplateName,
                                    _wellNumber => _wellNumber,
                                    _internalStandard => _internalStandard,
                                    _comment => _comment,
                                    _eusProposalID => _eusProposalID,
                                    _eusUsageType => _eusUsageType,
                                    _eusUsersList => _eusUsersList,
                                    _mode => _requestedRunMode,
                                    _request => _request,           -- Output
                                    _message => _message,           -- Output
                                    _returnCode => _returnCode,     -- Output
                                    _secSep => _separationGroup,
                                    _mrmAttachment => _mrmAttachment,
                                    _status => 'Active',
                                    _callingUser => _callingUser,
                                    _vialingConc => _vialingConc,
                                    _vialingVol => _vialingVol,
                                    _stagingLocation => _stagingLocation,
                                    _resolvedInstrumentInfo => _resolvedInstrumentInfoCurrent);      -- Output
            --
            _message := '[' || _experimentName || '] ' || _message;

            If _returnCode = '' And _mode = 'add' Then
                UPDATE Tmp_ExperimentsToProcess
                SET RequestID = _request
                WHERE EntryID = _entryID

                _requestedRunList := _requestedRunList || _request::text || ', ';
            End If;

            If _resolvedInstrumentInfo = '' And _resolvedInstrumentInfoCurrent <> '' Then
                _resolvedInstrumentInfo := _resolvedInstrumentInfoCurrent;
            End If;

            If _returnCode <> '' Then
                _logErrors := false;
                RAISE EXCEPTION '%', _message;
            End If;

            _count := _count + 1;

        END LOOP;

        If _mode::citext = 'PreviewAdd' Then
            _message := 'Would create ' || _count::text || ' requested runs (' || _requestNameFirst || ' to ' || _requestNameLast || ')';

            If _resolvedInstrumentInfo = '' Then
                _message := _message || ' with instrument group ' || _instrumentGroupToUse || ', run type ' || _msType || ', and separation group ' || _separationGroup;
            Else
                _message := _message || ' with ' || _resolvedInstrumentInfo;
            End If;
        Else
            _message := 'Number of requested runs created: ' || _count::text;
        End If;

        If char_length(_batchName) > 0 Then
            If _count <= 1 Then
                _message := public.append_to_text(_message, 'Not creating a batch since did not create multiple requested runs', 0, '; ', 1024);
            Else

                -- Auto-create a batch for the new requests
                Call add_update_requested_run_batch (
                                               _id => _batchID,             -- Output
                                               _name => _batchName,
                                               _description => _batchDescription,
                                               _requestedRunList => _requestedRunList,
                                               _ownerUsername => _operatorUsername,
                                               _requestedBatchPriority => _batchPriority,
                                               _requestedCompletionDate => _batchCompletionDate,
                                               _justificationHighPriority => _batchPriorityJustification,
                                               _requestedInstrumentGroup => _instrumentGroupToUse,
                                               _comment => _batchComment,
                                               _mode => _mode,
                                               _message => _msg,            -- Output
                                               _returnCode => _returnCode,  -- Output
                                               _useRaiseError => false);

                If _returnCode <> '' Then
                    If Coalesce(_msg, '') = '' Then
                        _msg := 'add_update_requested_run_batch returned error code ' || _returnCode;
                    Else
                        _msg := 'Error adding new batch, ' || _msg;
                    End If;
                Else
                    If _mode::citext = 'PreviewAdd' Then
                        _msg := 'Would create a batch named "' || _batchName || '"';
                    Else
                        _msg := 'Created batch ' || _batchID::text;
                    End If;
                End If;

                _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
            End If;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_ExperimentsToProcess;
END
$$;

COMMENT ON PROCEDURE public.add_requested_runs IS 'AddRequestedRuns';