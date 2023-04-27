--
CREATE OR REPLACE PROCEDURE pc.string_to_base64()
LANGUAGE plpgsql
AS $$
DECLARE
    _byteArray INT, _oLEResult INT;
BEGIN
EXECUTE _oLEResult = sp_OACreate 'ScriptUtils.ByteArray', _byteArray OUT
IF _oLEResult <> 0 PRINT 'ScriptUtils.ByteArray problem' Then
;
End If;
--Set a charset if needed.
--execute _oLEResult = sp_OASetProperty _byteArray, 'CharSet', "windows-1250"
--IF _oLEResult <> 0 PRINT 'CharSet problem'

--Set the string.
EXECUTE _oLEResult = sp_OASetProperty _byteArray, 'String', _string
IF _oLEResult <> 0 PRINT 'String problem' Then
;
End If;
--Get base64
EXECUTE _oLEResult = sp_OAGetProperty _byteArray, 'Base64', _base64 OUTPUT
IF _oLEResult <> 0 PRINT 'Base64 problem' Then
;
End If;
EXECUTE _oLEResult = sp_OADestroy _byteArray

RAISE INFO '%', _oLEResult;
END
$$;

COMMENT ON PROCEDURE pc.string_to_base64 IS 'StringToBase64';
