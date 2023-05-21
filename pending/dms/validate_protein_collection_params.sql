--
CREATE OR REPLACE PROCEDURE public.validate_protein_collection_params
(
    _toolName text,
    INOUT _organismDBName text,
    _organismName text,
    INOUT _protCollNameList text,
    INOUT _protCollOptionsList text,
    _ownerUsername text := '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _debugMode boolean := false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates the organism DB and/or protein collection options
**
**  Arguments:
**    _toolName           If blank, will assume _orgDbReqd=1
**    _protCollNameList   Will raise an error if over 4000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 4000 character limit on analysis job parameter values
**    _ownerUsername      Only required if the user chooses an 'Encrypted' protein collection; as of August 2010 we don't have any encrypted protein collections
**    _debugMode          If true, will display some debug info
**
**  Auth:   mem
**  Date:   08/26/2010
**          05/15/2012 mem - Now verifying that _organismDBName is 'na' if _protCollNameList is defined, or vice versa
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          08/19/2013 mem - Auto-clearing _organismDBName if both _organismDBName and _protCollNameList are defined and _organismDBName is the auto-generated FASTA file for the specified protein collection
**          07/12/2016 mem - Now using a synonym when calling ValidateAnalysisJobProteinParameters in the Protein_Sequences database
**          04/11/2022 mem - Increase warning threshold for length of _protCollNameList to 4000
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result int;
    _orgDbReqd int;
    _organismMatch text := '';
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _ownerUsername := Coalesce(_ownerUsername, '');
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
    --
    -- Since .NET string comparisons are case sensitive,
    -- _settingsFileName needs to be lowercase 'na' for compatibility with the analysis manager
    ---------------------------------------------------

    _organismDBName := public.validate_na_parameter(_organismDBName, 1);
    _protCollNameList := public.validate_na_parameter(_protCollNameList, 1);
    _protCollOptionsList := public.validate_na_parameter(_protCollOptionsList, 1);

    If _organismDBName = '' Then
        _organismDBName := 'na'
    End If;

    If _protCollNameList = '' Then
        _protCollNameList := 'na';
    End If;

    If _protCollOptionsList = '' Then
        _protCollOptionsList := 'na'
    End If;

    ---------------------------------------------------
    -- Lookup orgDbReqd for the analysis tool
    ---------------------------------------------------
    --
    _orgDbReqd := 0;

    If Coalesce(_toolName, '') = '' Then
        _orgDbReqd := 1;
    Else
        SELECT org_db_required
        INTO _orgDbReqd
        FROM t_analysis_tool
        WHERE analysis_tool = _toolName::citext;

        If Not FOUND Then
            _message := format('Invalid analysis tool "%s"; not found in t_analysis_tool', _toolName);
            _returnCode := 'U5309';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate the protein collection info
    ---------------------------------------------------

    If char_length(_protCollNameList) > 4000 Then
        _message := 'Protein collection list is too long; maximum length is 4000 characters';
        _returnCode := 'U5310';
        RETURN;
    End If;

    If _orgDbReqd = 0 Then
        If _organismDBName::citext <> 'na' OR _protCollNameList::citext <> 'na' OR _protCollOptionsList::citext <> 'na' Then
            _message := format('Protein parameters must all be "na"; you have: Legacy Fasta (OrgDBName) = "%s", ProteinCollectionList = "%s", ProteinOptionsList = "%s"',
                                _organismDBName, _protCollNameList,  _protCollOptionsList);

            _returnCode := 'U5393';
            RETURN;
        End If;

        RETURN;
    End If;

    If Not _organismDBName::citext In ('', 'na') And Not _protCollNameList::citext In ('', 'na') Then
        -- User defined both a Legacy Fasta file and a Protein Collection List
        -- Auto-change _organismDBName to 'na' if possible
        If Exists (SELECT * FROM t_analysis_job
                   WHERE organism_db_name = _organismDBName::citext AND
                         protein_collection_list = _protCollNameList::citext AND
                         job_state_id IN (1, 2, 4, 14)) Then

            -- Existing job found with both this legacy fasta file name and this protein collection list
            -- Thus, use the protein collection list and clear _organismDBName
            _organismDBName := '';

        End If;
    End If;

    If Not _organismDBName::citext In ('', 'na') Then
        If Not _protCollNameList::citext In ('', 'na') Then
            _message := 'Cannot define both a Legacy Fasta file and a Protein Collection List; one must be "na"';
            _returnCode := 'U5314';
            RETURN;
        End If;

        If _protCollNameList::citext In ('', 'na') and Not _protCollOptionsList::citext In ('', 'na') Then
            _protCollOptionsList := 'na';
        End If;

        -- Verify that _organismDBName is defined in t_organism_db_file and that the organism matches up

        If Not Exists ( SELECT *
                        FROM t_organism_db_file ODB INNER JOIN
                             t_organisms O ON ODB.organism_id = O.organism_id
                        WHERE ODB.file_name = _organismDBName::citext AND
                              O.organism = _organismName::citext AND
                              O.active > 0 AND
                              ODB.valid > 0) Then

            -- Match not found; try matching the name but not the organism

            SELECT O.organism
            INTO _organismMatch
            FROM t_organism_db_file ODB INNER JOIN
                 t_organisms O ON ODB.organism_id = O.organism_id
            WHERE ODB.file_name = _organismDBName::citext AND O.active > 0 AND ODB.valid > 0;

            If FOUND Then
                _message := format('Legacy Fasta file "%s" is defined for organism %s; you specified organism %s; cannot continue',
                                    _organismDBName, _organismMatch, _organismName);

                _returnCode := 'U5320';
                RETURN;
            Else
                -- Match still not found; check if it is disabled

                If Exists ( SELECT *
                            FROM t_organism_db_file ODB INNER JOIN
                                 t_organisms O ON ODB.organism_id = O.organism_id
                            WHERE ODB.file_name = _organismDBName::citext AND
                                  (O.active = 0 OR ODB.valid = 0)) Then

                    _message := format('Legacy Fasta file "%s" is disabled and cannot be used (see t_organism_db_file)', _organismDBName);
                    _returnCode := 'U5321';
                    RETURN;

                Else

                    _message := format('Legacy Fasta file "%s" is not a recognized fasta file', _organismDBName);
                    _returnCode := 'U5322';
                    RETURN;

                End If;
            End If;

        End If;

    End If;

    If _debugMode Then
        _message := 'Calling pc.validate_analysis_job_protein_parameters: ' ||;
                            Coalesce(_organismName, '??') || '; ' ||
                            Coalesce(_ownerUsername, '??') || '; ' ||
                            Coalesce(_organismDBName, '??') || '; ' ||
                            Coalesce(_protCollNameList, '??') || '; ' ||
                            Coalesce(_protCollOptionsList, '??')

        RAISE INFO '%', _message;
        -- call PostLogEntry ('Debug',_message, 'ValidateProteinCollectionParams');
        _message := '';
    End If;

    CALL pc.validate_analysis_job_protein_parameters (
            _organismName,
            _ownerUsername,
            _organismDBName,
            _protCollNameList => _protCollNameList,         -- Output
            _protCollOptionsList => _protCollOptionsList,   -- Output
            _message => _message,                           -- Output
            _returnCode => _returnCode);                    -- Output


END
$$;

COMMENT ON PROCEDURE public.validate_protein_collection_params IS 'ValidateProteinCollectionParams';

