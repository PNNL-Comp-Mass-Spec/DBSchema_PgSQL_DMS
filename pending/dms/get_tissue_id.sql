--
CREATE OR REPLACE PROCEDURE public.get_tissue_id
(
    _tissueNameOrID text,
    INOUT _tissueIdentifier text,
    INOUT _tissueName text,
    INOUT _message text default ''
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Gets tissue ID for given tissue name or tissue ID
**
**  Arguments:
**    _tissueNameOrID       Tissue name or tissue identifier to find
**    _tissueIdentifier     Output: Tissue identifier, e.g. BTO:0000131
**    _tissueName           Output: Human readable tissue name, e.g. plasma
**    _message              Output message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   09/01/2017 mem - Initial version
**          10/09/2017 mem - Auto-change _tissue to '' if 'none', 'na', or 'n/a'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    _tissueNameOrID := Trim(Coalesce(_tissueNameOrID, ''));

    _tissueIdentifier := null;
    _tissueName := null;

    If _tissueNameOrID::citext In ('none', 'na', 'n/a') Then
        _tissueNameOrID := '';
    End If;

    If char_length(_tissueNameOrID) > 0 Then
        If _tissueNameOrID ILike 'BTO:%' Then
            SELECT Identifier,
                   Tissue
            INTO _tissueIdentifier, _tissueName
            FROM ont.V_BTO_ID_to_Name
            WHERE Identifier = _tissueNameOrID::citext

            If Not FOUND Then
                _returnCode := 'U5201';
            End If;
        Else
            SELECT Identifier,
                   Tissue
            INTO _tissueIdentifier, _tissueName
            FROM ont.V_BTO_ID_to_Name
            WHERE Tissue = _tissueNameOrID::citext

            If Not FOUND Then
                _returnCode := 'U5202';
            End If;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE public.get_tissue_id IS 'GetTissueID';

