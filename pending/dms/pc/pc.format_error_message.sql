--
CREATE OR REPLACE PROCEDURE pc.format_error_message
(
    INOUT _message text,
    INOUT _myError int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Formats error message string
**          Must be called from within CATCH block
**
**  Return values:  Message string
**
**  Auth:   grk
**  Date:   04/16/2010 grk - Initial release
**          06/20/2018 mem - Allow for Error_Procedure() to be null
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _myError := ERROR_NUMBER();

    If _myError = 50000 Then
        _myError := 51000 + ERROR_STATE();
    End If;

    If ERROR_PROCEDURE() Is Null Then
        _message := ERROR_MESSAGE() || ' (Line ' || Cast(ERROR_LINE() As text) || ')';
    Else
        _message := ERROR_MESSAGE() || ' (' || ERROR_PROCEDURE() || ':' || Cast(ERROR_LINE() As text) || ')';
    End If;
END
$$;

COMMENT ON PROCEDURE pc.format_error_message IS 'FormatErrorMessage';
