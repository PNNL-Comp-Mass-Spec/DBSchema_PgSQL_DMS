--
CREATE OR REPLACE PROCEDURE pc.promote_protein_collection_state
(
    _addNewProteinHeaders boolean = true,
    _mostRecentMonths int = 12,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Examines protein collections with a state of 1
**          Looks in public.T_Analysis_Job
**          for any analysis jobs that refer to the given
**          protein collection.  If any are found, the state
**          for the given protein collection is changed to 3
**
**
**  Arguments:
**    _addNewProteinHeaders     When true, call add_new_protein_headers to add new proteins to pc.T_Protein_Headers
**    _mostRecentMonths         Used to filter protein collections that we will examine
**
**  Auth:   mem
**  Date:   09/13/2007
**          04/08/2008 mem - Added parameter _addNewProteinHeaders
**          02/23/2016 mem - Add set XACT_ABORT on
**          09/12/2016 mem - Add parameter _mostRecentMonths
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _proteinCollectionID int;
    _proteinCollectionName text;
    _nameFilter text;
    _jobCount int;
    _proteinCollectionsUpdated text := '';
    _proteinCollectionCountUpdated int := 0;
    _callingProcName text;
    _currentLocation text := 'Start';

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

    If _mostRecentMonths > 2000 Then
        _mostRecentMonths := 2000;
    End If;

    _infoOnly := Coalesce(_infoOnly, 0);

    --------------------------------------------------------------
    -- Loop through the protein collections with a state of 1
    -- Limit to protein collections created within the last _mostRecentMonths months
    --------------------------------------------------------------
    --
    BEGIN

        _proteinCollectionID := 0;

        WHILE true
        LOOP
            _currentLocation := 'Find the next Protein collection with state 1';

            SELECT protein_collection_id,
                   collection_name
            INTO _proteinCollectionID, _proteinCollectionName
            FROM pc.t_protein_collections
            WHERE collection_state_id = 1 AND
                  protein_collection_id > _proteinCollectionID AND
                  date_created >= DATEADD(month, -_mostRecentMonths, CURRENT_TIMESTAMP)
            ORDER BY protein_collection_id
            LIMIT 1;

            If Not FOUND Then
                -- Break out of the while loop
                EXIT;
            End If;

            _currentLocation := 'Look for jobs in V_DMS_Analysis_Job_Info that used ' || _proteinCollectionName;

            If _infoOnly Then
                RAISE INFO '%', _currentLocation;
            End If;

            _nameFilter := '%' || _proteinCollectionName || '%';

            SELECT COUNT(*)
            INTO _jobCount
            FROM public.T_Analysis_Job
            WHERE Protein_Collection_List ILIKE _nameFilter;

            If _jobCount > 0 Then
                _message := 'Updated state for Protein Collection "' || _proteinCollectionName || '" from 1 to 3 since ' || _jobCount::text || ' jobs are defined in DMS with this protein collection';

                If Not _infoOnly Then
                    _currentLocation := 'Update state for CollectionID ' || _proteinCollectionID::text;

                    UPDATE pc.t_protein_collections
                    SET collection_state_id = 3
                    WHERE protein_collection_id = _proteinCollectionID AND collection_state_id = 1

                    CALL public.post_log_entry ('Normal', _message, 'Promote_Protein_Collection_State', 'pc');
                Else
                    RAISE INFO '%', _message;
                End If;

                If char_length(_proteinCollectionsUpdated) > 0 Then
                    _proteinCollectionsUpdated := _proteinCollectionsUpdated || ', ';
                End If;

                _proteinCollectionsUpdated := _proteinCollectionsUpdated + _proteinCollectionName;
                _proteinCollectionCountUpdated := _proteinCollectionCountUpdated + 1;
            End If;
        END LOOP;

        _currentLocation := 'Done iterating';

        If _proteinCollectionCountUpdated = 0 Then
            _message := 'No protein collections were found with state 1 and jobs defined in DMS';
        Else
            -- If more than one collection was affected, update update _message with the overall stats
            If _proteinCollectionCountUpdated > 1 Then
                _message := 'Updated the state for ' || _proteinCollectionCountUpdated::text || ' protein collections from 1 to 3 since existing jobs were found: ' || _proteinCollectionsUpdated;
            End If;

        End If;

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        If _addNewProteinHeaders Then
            CALL Add_New_Protein_Headers (_infoOnly = _infoOnly);
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

COMMENT ON PROCEDURE pc.promote_protein_collection_state IS 'PromoteProteinCollectionState';
