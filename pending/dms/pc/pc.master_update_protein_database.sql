--
CREATE OR REPLACE PROCEDURE pc.master_update_protein_database
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
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
    _result int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN


    _message := '';
    _returnCode:= '';

    Begin Try

        SELECT enabled
        INTO _result
        FROM pc.t_process_step_control
        WHERE (processing_step_name = 'PromoteProteinCollectionStates');

        If _result > 0 Then
            _currentLocation := 'Call PromoteProteinCollectionState';
            Call promote_protein_collection_state (_message => _message,        -- Output
                                                   _returnCode => _returnCode); -- Output
            If _returnCode <> '' Then
                RETURN;
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