--
CREATE OR REPLACE PROCEDURE pc.promote_protein_collection_state
(
    _addNewProteinHeaders int = 1,
    _mostRecentMonths int = 12,
    _infoOnly int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Examines protein collections with a state of 1
**          Looks in MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
**          for any analysis jobs that refer to the given
**          protein collection.  If any are found, the state
**          for the given protein collection is changed to 3
**
**
**  Arguments:
**    _mostRecentMonths   Used to filter protein collections that we will examine
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
    _myRowCount int := 0;
    _continue int;
    _proteinCollectionID int;
    _proteinCollectionName text;
    _nameFilter text;
    _jobCount int;
    _proteinCollectionsUpdated text;
    _proteinCollectionCountUpdated int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN


    _proteinCollectionCountUpdated := 0;
    _proteinCollectionsUpdated := '';

    _message := '';
    _returnCode:= '';

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    _addNewProteinHeaders := Coalesce(_addNewProteinHeaders, 1);

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
    Begin Try

        _proteinCollectionID := 0;
        _continue := 1;

        While _continue = 1 Loop
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
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount <> 1 Then
                _continue := 0;
            Else
                _currentLocation := 'Look for jobs in V_DMS_Analysis_Job_Info that used ' || _proteinCollectionName;

                If _infoOnly > 0 Then
                    RAISE INFO '%', _currentLocation;
                End If;

                _nameFilter := '%' || _proteinCollectionName || '%';

                _jobCount := 0;
                SELECT COUNT(*) INTO _jobCount
                FROM MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
                WHERE (ProteinCollectionList LIKE _nameFilter)
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _jobCount > 0 Then
                    _message := 'Updated state for Protein Collection "' || _proteinCollectionName || '" from 1 to 3 since ' || _jobCount::text || ' jobs are defined in DMS with this protein collection';

                    If _infoOnly = 0 Then
                        _currentLocation := 'Update state for CollectionID ' || _proteinCollectionID::text;

                        UPDATE pc.t_protein_collections
                        SET collection_state_id = 3
                        WHERE protein_collection_id = _proteinCollectionID AND collection_state_id = 1

                        Call post_log_entry ('Normal', _message, 'Promote_Protein_Collection_State', 'pc');
                    Else
                        RAISE INFO '%', _message;
                    End If;

                    If char_length(_proteinCollectionsUpdated) > 0 Then
                        _proteinCollectionsUpdated := _proteinCollectionsUpdated || ', ';
                    End If;

                    _proteinCollectionsUpdated := _proteinCollectionsUpdated + _proteinCollectionName;
                    _proteinCollectionCountUpdated := _proteinCollectionCountUpdated + 1;
                End If;
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

        If _infoOnly > 0 Then
            RAISE INFO '%', _message;
        End If;

        If _addNewProteinHeaders <> 0 Then
            Exec AddNewProteinHeaders _infoOnly = _infoOnly;
        End If;

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        _callingProcName := Coalesce(ERROR_PROCEDURE(), 'PromoteProteinCollectionState');
        Call _logError => 1,
                                _errorNum = _myError output, _message = _message output
        Return;
    End Catch

Done:
    Return _myError
END
$$;

COMMENT ON PROCEDURE pc.promote_protein_collection_state IS 'PromoteProteinCollectionState';
