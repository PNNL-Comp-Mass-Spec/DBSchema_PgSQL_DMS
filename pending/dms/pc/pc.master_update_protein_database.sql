--
CREATE OR REPLACE PROCEDURE pc.master_update_protein_database
(
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Calls routine update procedures for the protein database
**
**  Auth:   mem
**  Date:   09/13/2007
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _result int;
    _callingProcName text;
    _currentLocation text;
BEGIN
    Set XACT_ABORT, nocount on

    _message := '';

    _currentLocation := 'Start';

    Begin Try

        _result := 0;
        SELECT enabled FROM pc.t_process_step_control WHERE (processing_step_name = 'PromoteProteinCollectionStates') INTO _result
        If _result > 0 Then
            _currentLocation := 'Call PromoteProteinCollectionState';
            Call promote_protein_collection_state _message => _message output
            If _myError <> 0 Then
                Goto Done;
            End If;
        End If;

        _message := '';

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        _callingProcName := Coalesce(ERROR_PROCEDURE(), 'MasterUpdateProteinDatabase');
        Call _logError => 1,
                                _errorNum = _myError output, _message = _message output
        Return;
    End Catch

Done:
    Return _myError
END
$$;

COMMENT ON PROCEDURE pc.master_update_protein_database IS 'MasterUpdateProteinDatabase';
