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
    INOUT _message text default '',
    INOUT _returnCode text default '',
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
**    _experimentGroupID            Specify ExperimentGroupID or ExperimentList, but not both
**    _experimentList               Comma-separated list of experiments
**    _requestNameSuffix            Actually used as the request name Suffix
**    _operatorUsername             Operator username
**    _instrumentGroup              Instrument group; could alternatively be '(lookup)'
**    _workPackage                  Work Package; could alternatively be '(lookup)'
**    _msType                       Run type; could alternatively be '(lookup)'
**    _instrumentSettings           Instrument settings
**    _eusProposalID                EUS proposal ID
**    _eusUsageType                 EUS usage type
**    _eusUsersList                 Comma-separated list of EUS user IDs (integers); also supports the form 'Baker, Erin (41136)'
**    _internalStandard             Internal standard
**    _comment                      Requested run comment
**    _mode                         Mode: 'add' or 'PreviewAdd'
**    _separationGroup              Separation group; could also contain '(lookup)'
**    _mrmAttachment                MRM attachment
**    _vialingConc                  Vialing concentration
**    _vialingVol                   Vialing volume
**    _stagingLocation              Staging location
**    _batchName                    If defined, create a new batch for the newly created requested runs
**    _batchDescription             Batch description
**    _batchCompletionDate          Batch completion date
**    _batchPriority                Batch priority
**    _batchPriorityJustification   Batch priority justification
**    _batchComment                 Batch comment
**    _message                      Output message
**    _returnCode                   Return code
**    _callingUser                  Calling user username
**
**  Auth:   grk
**  Date:   07/22/2005 - Initial version
**          07/27/2005 grk - Modified prefix
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
**          07/27/2009 grk - Removed autonumber for well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          03/02/2010 grk - Added status field to requested run
**          08/27/2010 mem - Now referring to _instrumentGroup as an instrument group
**          09/29/2011 grk - Fixed limited size of variable holding delimited list of experiments from group
**          12/14/2011 mem - Added parameter _callingUser, which is passed to Add_Update_Requested_Run
**          02/20/2012 mem - Now using a temporary table to track the experiment names for which requested runs need to be created
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          06/13/2013 mem - Added _vialingConc and _vialingVol
                           - Now validating _workPackageNumber against T_Charge_Code
**          06/18/2014 mem - Now passing default to Parse_Delimited_List
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**          12/12/2017 mem - Add _stagingLocation (points to T_Material_Locations)
**          05/29/2021 mem - Add parameters to allow also creating a batch
**          06/01/2021 mem - Show names of the new requests when previewing updates
**          07/01/2021 mem - Rename instrument parameter to be _instrumentGroup
**                         - Add parameters _batchPriorityJustification and _batchComment
**          07/09/2021 mem - Fix bug handling instrument group name when _batchName is blank
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/17/2022 mem - Update operator username warning
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Update call to Add_Update_Requested_Run to use new parameter name
**          02/14/2023 mem - Use new parameter names for validate_requested_run_batch_params
**          02/17/2023 mem - Use new parameter name when calling Add_Update_Requested_RunBatch
**          02/27/2023 mem - Use new argument name, _requestName
**          11/27/2023 mem - Do not log errors from validate_requested_run_batch_params() if the return code starts with 'U52' (e.g., 'U5201')
**          12/15/2024 mem - Ported to PostgreSQL
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
        -- Validate the inputs
        ---------------------------------------------------

        _experimentGroupID := Trim(Coalesce(_experimentGroupID, ''));
        _experimentList    := Trim(Coalesce(_experimentList, ''));
        _batchName         := Trim(Coalesce(_batchName, ''));

        If _experimentGroupID <> '' And _experimentList <> '' Then
            _returnCode := 'U5130';
            _message := 'Experiment Group ID and Experiment List cannot both be non-blank';
            RAISE EXCEPTION '%', _message;
        End If;

        If _experimentGroupID = '' And _experimentList = '' Then
            _returnCode := 'U5131';
            _message := 'Experiment Group ID and Experiment List cannot both be blank';
            RAISE EXCEPTION '%', _message;
        End If;

        If char_length(_experimentGroupID) > 0 Then
            _experimentGroupIDVal := public.try_cast(_experimentGroupID, null::int);

            If _experimentGroupIDVal Is Null Then
                _returnCode := 'U5132';
                _message := format('Experiment Group ID must be a number: %s', _experimentGroupID);
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        If char_length(_operatorUsername) < 1 Then
            _returnCode := 'U5113';
            RAISE EXCEPTION 'Operator username must be specified';
        End If;

        If char_length(_instrumentGroup) < 1 Then
            _returnCode := 'U5114';
            RAISE EXCEPTION 'Instrument group must be specified';
        End If;

        If char_length(_msType) < 1 Then
            _returnCode := 'U5115';
            RAISE EXCEPTION 'Dataset type must be specified';
        End If;

        If char_length(_workPackage) < 1 Then
            _returnCode := 'U5116';
            RAISE EXCEPTION 'Work package must be specified';
        End If;

        If _returnCode <> '' Then
            RETURN;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Validate the work package
        -- This validation also occurs in Add_Update_Requested_Run but we want to validate it now before we enter the while loop
        ---------------------------------------------------

        If _workPackage <> '(lookup)' Then
            CALL public.validate_wp (
                            _workPackageNumber,
                            _allowNoneWP,
                            _message    => _msg,            -- Output
                            _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'validate_wp: %', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Validation checks are complete; now enable _logErrors
        ---------------------------------------------------

        _logErrors := true;

        ---------------------------------------------------
        -- Resolve staging location name to location ID
        ---------------------------------------------------

        If Coalesce(_stagingLocation, '') <> '' Then
            SELECT location_id
            INTO _locationID
            FROM t_material_locations
            WHERE location = _stagingLocation;

            If Not FOUND Then
                RAISE EXCEPTION 'Staging location not recognized: %', _stagingLocation;
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

        If char_length(_batchName) > 0 Then
            ---------------------------------------------------
            -- Validate batch fields
            ---------------------------------------------------

            CALL public.validate_requested_run_batch_params (
                            _batchID                   => 0,
                            _name                      => _batchName,
                            _description               => _batchDescription,
                            _ownerUsername             => _operatorUsername,
                            _requestedBatchPriority    => _batchPriority,
                            _requestedCompletionDate   => _batchCompletionDate,
                            _justificationHighPriority => _batchPriorityJustification,
                            _requestedInstrumentGroup  => _instrumentGroup,              -- Will typically contain an instrument group, not an instrument name
                            _comment                   => _batchComment,
                            _mode                      => _mode,
                            _instrumentGroupToUse      => _instrumentGroupToUse,    -- Output
                            _userID                    => _userID,                  -- Output
                            _message                   => _message,                 -- Output
                            _returnCode                => _returnCode);             -- Output

            If _returnCode <> '' Then

                -- Do not log errors to t_log_entries when the return code starts with 'U52', but do raise an exception so the user sees the message
                If _returnCode Like 'U52%' Then
                    _logErrors := false;
                End If;

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
            _suffix := format('_%s', _suffix);
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

            CALL public.add_update_requested_run (
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
            _message := format('[%s] %s', _experimentName, _message);

            If _returnCode = '' And _mode = 'add' Then
                UPDATE Tmp_ExperimentsToProcess
                SET RequestID = _request
                WHERE EntryID = _entryID;

                If _requestedRunList = '' Then
                    _requestedRunList := format('%s', _request);
                Else
                    _requestedRunList := format('%s, %s', _requestedRunList, _request);
                End If

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
            _message := format('Would create %s requested %s (%s to %s)',
                                _count,
                                public.check_plural(_count, 'run', 'runs'),
                                _requestNameFirst, _requestNameLast);

            If _resolvedInstrumentInfo = '' Then
                _message := format('%s with instrument group %s, run type %s, and separation group %s',
                                    _message, _instrumentGroupToUse, _msType, _separationGroup);
            Else
                _message := format('%s with %s', _message, _resolvedInstrumentInfo);
            End If;
        Else
            _message := format('Number of requested runs created: %s', _count);
        End If;

        If char_length(_batchName) > 0 Then
            If _count <= 1 Then
                _message := public.append_to_text(_message, 'Not creating a batch since did not create multiple requested runs');
            Else

                -- Auto-create a batch for the new requests
                CALL public.add_update_requested_run_batch (
                               _id                        => _batchID,          -- Output
                               _name                      => _batchName,
                               _description               => _batchDescription,
                               _requestedRunList          => _requestedRunList,
                               _ownerUsername             => _operatorUsername,
                               _requestedBatchPriority    => _batchPriority,
                               _requestedCompletionDate   => _batchCompletionDate,
                               _justificationHighPriority => _batchPriorityJustification,
                               _requestedInstrumentGroup  => _instrumentGroupToUse,
                               _comment                   => _batchComment,
                               _mode                      => _mode,
                               _message                   => _msg,              -- Output
                               _returnCode                => _returnCode,       -- Output
                               _useRaiseError             => false);

                If _returnCode <> '' Then
                    If Coalesce(_msg, '') = '' Then
                        _msg := format('add_update_requested_run_batch returned error code %s', _returnCode);
                    Else
                        _msg := format('Error adding new batch, %s', _msg);
                    End If;
                Else
                    If _mode::citext = 'PreviewAdd' Then
                        _msg := format('Would create a batch named "%s"', _batchName);
                    Else
                        _msg := format('Created batch %s', _batchID);
                    End If;
                End If;

                _message := public.append_to_text(_message, _msg);
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
