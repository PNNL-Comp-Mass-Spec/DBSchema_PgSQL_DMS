--
-- Name: get_tissue_id(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_tissue_id(IN _tissuenameorid text, INOUT _tissueidentifier text, INOUT _tissuename text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get tissue ID for given tissue name or tissue ID
**
**  Arguments:
**    _tissueNameOrID       Tissue name or tissue identifier to find
**    _tissueIdentifier     Output: Tissue identifier, e.g. BTO:0000131
**    _tissueName           Output: Human readable tissue name, e.g. plasma
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   09/01/2017 mem - Initial version
**          10/09/2017 mem - Auto-change _tissue to '' if 'none', 'na', or 'n/a'
**          12/05/2023 mem - Ported to PostgreSQL
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          08/23/2024 mem - Directly reference t_cv_bto_cached_names
**          08/26/2024 mem - Fix column name bug referencing t_cv_bto_cached_names
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
        RETURN;
    End If;

    If _tissueNameOrID <> '' Then
        If _tissueNameOrID ILike 'BTO:%' Then
            SELECT identifier,
                   term_name AS tissue
            INTO _tissueIdentifier, _tissueName
            FROM ont.t_cv_bto_cached_names
            WHERE identifier = _tissueNameOrID::citext;

            If Not FOUND Then
                _message := format('Identifier not found: %s', _tissueNameOrID);
                _returnCode := 'U5201';
            End If;
        Else
            SELECT identifier,
                   term_name AS tissue
            INTO _tissueIdentifier, _tissueName
            FROM ont.t_cv_bto_cached_names
            WHERE term_name = _tissueNameOrID::citext;

            If Not FOUND Then
                 _message := format('Tissue name not found: %s', _tissueNameOrID);
                _returnCode := 'U5202';
            End If;
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.get_tissue_id(IN _tissuenameorid text, INOUT _tissueidentifier text, INOUT _tissuename text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_tissue_id(IN _tissuenameorid text, INOUT _tissueidentifier text, INOUT _tissuename text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_tissue_id(IN _tissuenameorid text, INOUT _tissueidentifier text, INOUT _tissuename text, INOUT _message text, INOUT _returncode text) IS 'GetTissueID';

