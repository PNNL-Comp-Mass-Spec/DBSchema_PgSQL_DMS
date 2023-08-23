--
-- Name: promote_protein_collection_state(boolean, integer, boolean, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.promote_protein_collection_state(IN _addnewproteinheaders boolean DEFAULT true, IN _mostrecentmonths integer DEFAULT 12, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for protein collections with a state of 1 in pc.t_protein_collections
**      For each, looks for analysis jobs in public.t_analysis_job that use the given protein collection
**      If any jobs are found, updates the protein collection state to 3
**
**  Arguments:
**    _addNewProteinHeaders     When true, call pc.add_new_protein_headers to add new proteins to pc.t_protein_headers
**    _mostRecentMonths         Used to filter which protein collections will be examined (if 0 or negative, will use 12 instead)
**    _infoOnly                 When true, preview updates
**
**  Auth:   mem
**  Date:   09/13/2007
**          04/08/2008 mem - Added parameter _addNewProteinHeaders
**          02/23/2016 mem - Add set XACT_ABORT on
**          09/12/2016 mem - Add parameter _mostRecentMonths
**          08/22/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dateThreshold timestamp;

    _countProcessed int;
    _countTotal int;
    _lastStatusTime timestamp;

    _proteinCollectionID int;
    _proteinCollectionName text;
    _nameFilter text;
    _jobCount int;
    _proteinCollectionsUpdated text := '';
    _proteinCollectionCountUpdated int := 0;
    _callingProcName text;
    _currentLocation text := 'Start';
    _msg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    _addNewProteinHeaders := Coalesce(_addNewProteinHeaders, true);

    _mostRecentMonths := Coalesce(_mostRecentMonths, 12);

    If _mostRecentMonths <= 0 Then
        _mostRecentMonths := 12;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    --------------------------------------------------------------
    -- Loop through the protein collections with a state of 1
    -- Limit to protein collections created within the last _mostRecentMonths months
    --------------------------------------------------------------

    BEGIN
        _dateThreshold := (CURRENT_TIMESTAMP + make_interval(months => -Abs(_mostRecentMonths)))::date;

        _lastStatusTime := clock_timestamp();

        SELECT COUNT(*)
        INTO _countTotal
        FROM pc.t_protein_collections
        WHERE collection_state_id = 1 AND
              date_created >= _dateThreshold;

        _countProcessed := 0;

        RAISE INFO '';

        If _countTotal = 0 Then
            RAISE INFO 'Did not find any protein collections created after % that have state 1', _dateThreshold;
        Else
            RAISE INFO 'Examining % protein % created after % that have state 1',
                            _countTotal,
                            public.check_plural(_countTotal, 'collection', 'collections'),
                            _dateThreshold;
        End If;

        FOR _proteinCollectionID, _proteinCollectionName IN
            SELECT protein_collection_id, collection_name
            FROM pc.t_protein_collections
            WHERE collection_state_id = 1 AND
                  date_created >= _dateThreshold
            ORDER BY protein_collection_id
        LOOP
            _currentLocation := format('Look for jobs in public.t_analysis_job that used %s', _proteinCollectionName);

            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO '%', _currentLocation;
            ElseIf extract(epoch FROM (clock_timestamp() - _lastStatusTime)) > 4 Then
                -- Show a status message since four seconds have elapsed
                RAISE INFO ' ... processed % / % protein collections', _countProcessed, _countTotal;
                _lastStatusTime := clock_timestamp();
            End If;

            _nameFilter := '%' || _proteinCollectionName || '%';

            SELECT COUNT(job)
            INTO _jobCount
            FROM public.t_analysis_job
            WHERE protein_collection_list ILIKE _nameFilter;

            If _jobCount > 0 Then
                _message := format('%s state from 1 to 3 for protein collection "%s" since %s defined in DMS with this protein collection',
                                   CASE WHEN _infoOnly THEN 'Would update' ELSE 'Updated' END,
                                   _proteinCollectionName,
                                   public.check_plural(_jobCount, 'a job is', _jobCount::text || ' jobs are'));

                If _infoOnly Then
                    RAISE INFO '%', _message;
                Else
                    _currentLocation := format('Update state for Collection ID %s', _proteinCollectionID);

                    UPDATE pc.t_protein_collections
                    SET collection_state_id = 3
                    WHERE protein_collection_id = _proteinCollectionID;

                    CALL public.post_log_entry ('Normal', _message, 'Promote_Protein_Collection_State', 'pc');
                End If;

                _proteinCollectionsUpdated := public.append_to_text(_proteinCollectionsUpdated, _proteinCollectionName, _delimiter => ', ');
                _proteinCollectionCountUpdated := _proteinCollectionCountUpdated + 1;

            ElsIf _infoOnly Then
                RAISE INFO 'Protein collection not used by any analysis jobs, leaving state as 1: %', _proteinCollectionName;
            End If;

            _countProcessed := _countProcessed + 1;
        END LOOP;

        _currentLocation := 'Done iterating';

        If _proteinCollectionCountUpdated = 0 Then
            _message := 'No protein collections were found with state 1 and jobs defined in DMS';
        Else
            -- If more than one collection was affected, update _message with the overall stats
            If _proteinCollectionCountUpdated > 1 Then
                _message := format('%s the state for %s protein %s from 1 to 3 since existing jobs were found: %s',
                                   CASE WHEN _infoOnly THEN 'Would update' ELSE 'Updated' END,
                                   _proteinCollectionCountUpdated,
                                   public.check_plural(_proteinCollectionCountUpdated, 'collection', 'collections'),
                                   _proteinCollectionsUpdated);
            End If;

        End If;

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO '%', _message;
        End If;

        If _addNewProteinHeaders Then
            CALL pc.add_new_protein_headers (
                    _infoOnly => _infoOnly,
                    _message => _msg,               -- Output
                    _returncode => _returncode);    -- Output

            If _returnCode <> '' Then
                _message = public.append_to_text (_message, _msg);
            End If;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE pc.promote_protein_collection_state(IN _addnewproteinheaders boolean, IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE promote_protein_collection_state(IN _addnewproteinheaders boolean, IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.promote_protein_collection_state(IN _addnewproteinheaders boolean, IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'PromoteProteinCollectionState';

