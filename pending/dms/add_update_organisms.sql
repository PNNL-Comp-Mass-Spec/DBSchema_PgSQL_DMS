
CREATE OR REPLACE PROCEDURE public.add_update_organisms
(
    _orgName text,
    _orgShortName text,
    _orgStorageLocation text,
    _orgDBName text,
    _orgDescription text,
    _orgDomain text,
    _orgKingdom text,
    _orgPhylum text,
    _orgClass text,
    _orgOrder text,
    _orgFamily text,
    _orgGenus text,
    _orgSpecies text,
    _orgStrain text,
    _orgActive text,
    _newtIDList text,
    _ncbiTaxonomyID int,
    _autoDefineTaxonomy text,
    INOUT _id int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing organism
**
**  Arguments:
**    _orgName              Organism name, e.g. 'Homo_sapiens'
**    _orgShortName         Abbreviated name, e.g. 'H_sapiens'
**    _orgStorageLocation   Storage location (server share), e.g. '\\gigasax\DMS_Organism_Files\Homo_sapiens\'
**    _orgDBName            Default protein collection name (prior to 2012 was default fasta file)
**    _orgDescription       Organism description
**    _orgDomain            Domain
**    _orgKingdom           Kingdom
**    _orgPhylum            Phylum
**    _orgClass             Class
**    _orgOrder             Order
**    _orgFamily            Family
**    _orgGenus             Genus
**    _orgSpecies           Species
**    _orgStrain            Strain
**    _orgActive            Active flag: '1' means active, '0' means inactive; when inactive, the organism will not appear in certain views
**    _newtIDList           If blank, this is auto-populated using _ncbiTaxonomyID
**    _ncbiTaxonomyID       NCBI taxonomy ID; this is the preferred way to define the taxonomy ID for the organism. NEWT ID is typically identical to taxonomy ID
**    _autoDefineTaxonomy   Auto define taxonomy: 'Yes' or 'No'
**    _id                   Input/Output: Organism ID in t_organisms
**    _mode                 Mode: 'add' or 'update'
**    _message              Output message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   grk
**  Date:   03/07/2006
**          01/12/2007 jds - Added support for new field OG_Active
**          01/12/2007 mem - Added validation that genus, species, and strain are not duplicated in T_Organisms
**          10/16/2007 mem - Updated to allow genus, species, and strain to all be 'na' (Ticket #562)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          09/12/2008 mem - Updated to call validate_na_parameter to validate genus, species, and strain (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          09/09/2009 mem - No longer populating field OG_organismDBLocalPath
**          11/20/2009 mem - Removed parameter _orgDBLocalPath
**          12/03/2009 mem - Now making sure that _orgDBPath starts with two slashes and ends with one slash
**          08/04/2010 grk - Use try-catch for error handling
**          08/01/2012 mem - Now calling Refresh_Cached_Organisms in MT_Main on ProteinSeqs
**          09/25/2012 mem - Expanded _orgName and _orgDBName to varchar(128)
**          11/20/2012 mem - No longer allowing _orgDBName to contain '.fasta'
**          05/10/2013 mem - Added _newtIdentifier
**          05/13/2013 mem - Now validating _newtIdentifier against ont.V_CV_NEWT
**          05/24/2013 mem - Added _newtIDList
**          10/15/2014 mem - Removed _orgDBPath and added validation logic to _orgStorageLocation
**          06/25/2015 mem - Now validating that the protein collection specified by _orgDBName exists
**          09/10/2015 mem - Switch to using synonym S_MT_Main_Refresh_Cached_Organisms
**          02/23/2016 mem - Add Set XACT_ABORT on
**          02/26/2016 mem - Check for _orgName containing a space
**          03/01/2016 mem - Added _ncbiTaxonomyID
**          03/02/2016 mem - Added _autoDefineTaxonomy
**                         - Removed parameter _newtIdentifier since superseded by _ncbiTaxonomyID
**          03/03/2016 mem - Now storing _autoDefineTaxonomy in column Auto_Define_Taxonomy
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          12/02/2016 mem - Assure that _orgName and _orgShortName do not have any spaces or commas
**          02/06/2017 mem - Auto-update _newtIDList to match _ncbiTaxonomyID if _newtIDList is null or empty
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/23/2017 mem - Check for the protein collection specified by _orgDBName being a valid name, but inactive
**          04/09/2018 mem - Auto-define _orgStorageLocation if empty
**          06/26/2019 mem - Remove DNA translation table arguments since unused
**          04/15/2020 mem - Populate OG_Storage_URL using _orgStorageLocation
**          09/14/2020 mem - Expand the description field to 512 characters
**          12/11/2020 mem - Allow duplicate metagenome organisms
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          04/11/2022 mem - Check for whitespace in _orgName
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying pc.V_Protein_Collections_By_Organism
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _duplicateTaxologyMsg text;
    _matchCount int;
    _serverNameEndSlash int;
    _serverName text;
    _pathForURL text;
    _orgStorageURL text := '';
    _orgDbPathBase text := '\\gigasax\DMS_Organism_Files\';
    _invalidNEWTIDs text := null;
    _autoDefineTaxonomyFlag int;
    _existingOrganismID int := 0;
    _existingOrgName text;
    _orgActiveID int;
    _logMessage text;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _orgStorageLocation := Trim(Coalesce(_orgStorageLocation, ''));

        If _orgStorageLocation <> '' Then
            If Not _orgStorageLocation Like '\\\\%' Then
                RAISE EXCEPTION 'Org. Storage Path must start with \\';
            End If;

            -- Make sure _orgStorageLocation does not End in \FASTA or \FASTA\
            -- That text gets auto-appended via computed column organism_db_path
            If _orgStorageLocation ILike '%\\FASTA' Then
                _orgStorageLocation := Substring(_orgStorageLocation, 1, char_length(_orgStorageLocation) - 6);
            End If;

            If _orgStorageLocation ILike '%\\FASTA\\' Then
                _orgStorageLocation := Substring(_orgStorageLocation, 1, char_length(_orgStorageLocation) - 7);
            End If;

            If Not _orgStorageLocation Like '%\\' Then
                _orgStorageLocation := format('%s\', _orgStorageLocation);
            End If;

            If char_length(_orgStorageLocation) > 3 Then
                -- Auto-define _orgStorageURL

                -- Find the next slash after the 3rd character
                _serverNameEndSlash := Position('\' In Substring(_orgStorageLocation, 3)) + 2;

                If _serverNameEndSlash > 3 Then
                    _serverName := Substring(_orgStorageLocation, 3, _serverNameEndSlash - 3);
                    _pathForURL := Substring(_orgStorageLocation, _serverNameEndSlash + 1, char_length(_orgStorageLocation));
                    _orgStorageURL := format('https://%s/%s', _serverName, Replace(_pathForURL, '\', '/'));
                End If;

            End If;

        End If;

        _orgName := Trim(Coalesce(_orgName, ''));
        If char_length(_orgName) < 1 Then
            RAISE EXCEPTION 'Organism Name must be specified';
        End If;

        If public.has_whitespace_chars(_orgName, _allowspace => false) Then
            If Position(chr(9) In _orgName) > 0 Then
                RAISE EXCEPTION 'Organism name cannot contain tabs';
            Else
                RAISE EXCEPTION 'Organism name cannot contain spaces';
            End If;
        End If;

        If _orgName Like '%,%' Then
            RAISE EXCEPTION 'Organism Name cannot contain commas';
        End If;

        If char_length(_orgStorageLocation) = 0 Then
            -- Auto define _orgStorageLocation

            SELECT server
            INTO _orgDbPathBase
            FROM t_misc_paths
            WHERE path_function = 'DMSOrganismFiles'

            _orgStorageLocation := format('%s\', public.combine_paths(_orgDbPathBase, _orgName));
        End If;

        If char_length(Coalesce(_orgShortName, '')) > 0 Then
            _orgShortName := Trim(Coalesce(_orgShortName, ''));

            If _orgShortName Like '% %' Then
                RAISE EXCEPTION 'Organism Short Name cannot contain spaces';
            End If;

            If _orgShortName Like '%,%' Then
                RAISE EXCEPTION 'Organism Short Name cannot contain commas';
            End If;
        End If;

        _orgDBName := Trim(Coalesce(_orgDBName, ''));

        If _orgDBName ILike '%.fasta' Then
            RAISE EXCEPTION 'Default Protein Collection cannot contain ".fasta"';
        End If;

        _orgActive   := Trim(Coalesce(_orgActive, ''));
        _orgActiveID := public.try_cast(_orgActive, -1);

        If char_length(_orgActive) = 0 Or Or Not Coalesce(_orgActiveID, -1) In (0, 1) Then
            RAISE EXCEPTION 'Organism active state must be 0 or 1';
        End If;

        _orgGenus   := Trim(Coalesce(_orgGenus, ''));
        _orgSpecies := Trim(Coalesce(_orgSpecies, ''));
        _orgStrain  := Trim(Coalesce(_orgStrain, ''));

        _autoDefineTaxonomy := Trim(Coalesce(_autoDefineTaxonomy, 'Yes'));

        -- Organism ID
        _id := Coalesce(_id, 0);

        _newtIDList := Trim(Coalesce(_newtIDList, ''));

        If char_length(_newtIDList) > 0 Then
            CREATE TEMP TABLE Tmp_NEWT_IDs (
                NEWT_ID_Text text,
                NEWT_ID int NULL
            )

            INSERT INTO Tmp_NEWT_IDs (NEWT_ID_Text)
            SELECT Value
            FROM public.parse_delimited_list(_newtIDList)
            WHERE Coalesce(Value, '') <> ''

            -- Look for non-numeric values
            If Exists (SELECT NEWT_ID_Text FROM Tmp_NEWT_IDs WHERE public.try_cast(NEWT_ID_Text, null::int) IS NULL) Then
                RAISE EXCEPTION 'Non-numeric NEWT ID values found in the NEWT_ID List: "%"; see https://dms2.pnl.gov/ontology/report/NEWT', _newtIDList;
            End If;

            -- Make sure all of the NEWT IDs are Valid
            UPDATE Tmp_NEWT_IDs
            Set NEWT_ID = public.try_cast(NEWT_ID_Text, null::int)

            SELECT string_agg(Tmp_NEWT_IDs.NEWT_ID_Text, ', ' ORDER BY Tmp_NEWT_IDs.NEWT_ID_Text)
            INTO _invalidNEWTIDs
            FROM Tmp_NEWT_IDs
                 LEFT OUTER JOIN S_V_CV_NEWT
                   ON Tmp_NEWT_IDs.NEWT_ID = S_V_CV_NEWT.identifier
            WHERE ont.V_CV_NEWT.identifier IS NULL

            If char_length(Coalesce(_invalidNEWTIDs, '')) > 0 Then
                RAISE EXCEPTION 'Invalid NEWT ID(s) "%"; see https://dms2.pnl.gov/ontology/report/NEWT', _invalidNEWTIDs;
            End If;

        Else
            -- Auto-define _newtIDList using _ncbiTaxonomyID though only if the NEWT table has the ID
            -- (there are numerous organisms that nave an NCBI Taxonomy ID but not a NEWT ID)
            --
            If Exists (SELECT Identifier FROM ont.V_CV_NEWT WHERE Identifier = _ncbiTaxonomyID::citext Then
                _newtIDList := _ncbiTaxonomyID::text;
            End If;
        End If;

        If Coalesce(_ncbiTaxonomyID, 0) = 0 Then
            _ncbiTaxonomyID := null;
        ElsIf Not Exists (SELECT Tax_ID FROM ont.V_NCBI_Taxonomy_Cached WHERE Tax_ID = _ncbiTaxonomyID) Then
            RAISE EXCEPTION 'Invalid NCBI Taxonomy ID "%"; see https://dms2.pnl.gov/ncbi_taxonomy/report', _ncbiTaxonomyID;
        End If;

        If _autoDefineTaxonomy ILike 'Y%' Then
            _autoDefineTaxonomyFlag := 1;
        Else
            _autoDefineTaxonomyFlag := 0;
        End If;

        If _autoDefineTaxonomyFlag = 1 And Coalesce(_ncbiTaxonomyID, 0) > 0 Then

            ---------------------------------------------------
            -- Try to auto-update the taxonomy information
            -- Existing values are preserved if matches are not found
            ---------------------------------------------------

            CALL public.get_taxonomy_value_by_taxonomy_id (
                            _ncbiTaxonomyID,
                            _orgDomain      => _orgDomain,      -- Output
                            _orgKingdom     => _orgKingdom,     -- Output
                            _orgPhylum      => _orgPhylum,      -- Output
                            _orgClass       => _orgClass,       -- Output
                            _orgOrder       => _orgOrder,       -- Output
                            _orgFamily      => _orgFamily,      -- Output
                            _orgGenus       => _orgGenus,       -- Output
                            _orgSpecies     => _orgSpecies,     -- Output
                            _orgStrain      => _orgStrain,      -- Output
                            _previewResults => false);

        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        -- Cannot create an entry that already exists
        --
        If _mode = 'add' Then
            _existingOrganismID := public.get_organism_id(_orgName);

            If _existingOrganismID <> 0 Then
                RAISE EXCEPTION 'Cannot add: Organism "%" already in database', _orgName;
            End If;
        End If;

        -- Cannot update a non-existent entry
        --
        If _mode = 'update' Then

            SELECT organism
            INTO _existingOrgName
            FROM  t_organisms
            WHERE organism_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: Organism "%" is not in database', _orgName;
            End If;

            If _existingOrgName <> _orgName Then
                RAISE EXCEPTION 'Cannot update: Organism name may not be changed from "%"', _existingOrgName;
            End If;
        End If;

        ---------------------------------------------------
        -- If Genus, Species, and Strain are unknown, na, or none,
        -- make sure all three are 'na'
        ---------------------------------------------------

        _orgGenus   := public.validate_na_parameter(_orgGenus);
        _orgSpecies := public.validate_na_parameter(_orgSpecies);
        _orgStrain  := public.validate_na_parameter(_orgStrain);

        If _orgGenus::citext   In ('unknown', 'na', 'none') And
           _orgSpecies::citext In ('unknown', 'na', 'none') And
           _orgStrain::citext  In ('unknown', 'na', 'none') Then

            _orgGenus   := 'na';
            _orgSpecies := 'na';
            _orgStrain  := 'na';

        End If;

        ---------------------------------------------------
        -- Check whether an organism already exists with the specified Genus, Species, and Strain
        -- Allow exceptions for metagenome organisms
        ---------------------------------------------------

        _duplicateTaxologyMsg := format('Another organism was found with Genus "%s", Species "%s", and Strain "%s"; if unknown, use "na" for these values',
                                        _orgGenus, _orgSpecies, _orgStrain);

        If Not (_orgGenus = 'na' And _orgSpecies = 'na' And _orgStrain = 'na') Then

            If _mode = 'add' Then
                -- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain

                SELECT COUNT(organism_id)
                INTO _matchCount
                FROM t_organisms
                WHERE Coalesce(genus, '')   = _orgGenus::citext AND
                      Coalesce(species, '') = _orgSpecies::citext AND
                      Coalesce(strain, '')  = _orgStrain::citext;

                If _matchCount <> 0 And Not _orgSpecies Like '%metagenome' Then
                    RAISE EXCEPTION 'Cannot add: %', _duplicateTaxologyMsg;
                End If;
            End If;

            If _mode = 'update' Then
                -- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain (ignoring Organism_ID = _id)

                SELECT COUNT(organism_id)
                INTO _matchCount
                FROM t_organisms
                WHERE Coalesce(genus, '')   = _orgGenus::citext AND
                      Coalesce(species, '') = _orgSpecies::citext AND
                      Coalesce(strain, '')  = _orgStrain::citext AND
                      organism_id <> _id;

                If _matchCount <> 0 And Not _orgSpecies Like '%metagenome' Then
                    RAISE EXCEPTION 'Cannot update: %', _duplicateTaxologyMsg;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the default protein collection
        ---------------------------------------------------

        If _orgDBName <> '' Then
            -- Protein collections in pc.V_Collection_Picker are those with state 1, 2, or 3
            -- In contrast, pc.V_Protein_Collections_by_Organism has all protein collections

            If Not Exists (SELECT Name FROM pc.V_Collection_Picker WHERE Name = _orgDBName) Then

                If Exists (SELECT Collection_Name FROM pc.V_Protein_Collections_by_Organism WHERE Collection_Name = _orgDBName AND Collection_State_ID = 4) Then
                    RAISE EXCEPTION 'Default protein collection is invalid because it is inactive: ', _orgDBName;
                Else
                    RAISE EXCEPTION 'Protein collection not found: %', _orgDBName;
                End If;

            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_organisms (
                organism,
                organism_db_name,
                created,
                description,
                short_name,
                storage_location,
                storage_url,
                domain,
                kingdom,
                phylum,
                class,
                order,
                family,
                genus,
                species,
                strain,
                active,
                newt_id_list,
                ncbi_taxonomy_id,
                auto_define_taxonomy
            ) VALUES (
                _orgName,
                _orgDBName,
                CURRENT_TIMESTAMP,
                _orgDescription,
                _orgShortName,
                _orgStorageLocation,
                _orgStorageURL,
                _orgDomain,
                _orgKingdom,
                _orgPhylum,
                _orgClass,
                _orgOrder,
                _orgFamily,
                _orgGenus,
                _orgSpecies,
                _orgStrain,
                _orgActive,
                _newtIDList,
                _ncbiTaxonomyID,
                _autoDefineTaxonomyFlag
            )
            RETURNING organism_id
            INTO _id;

            -- If _callingUser is defined, update entered_by in t_organisms_change_history
            If char_length(_callingUser) > 0 Then
                CALL public.alter_entered_by_user ('public', 't_organisms_change_history', 'organism_id', _id, _callingUser, _message => _alterEnteredByMessage);
            End If;

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            UPDATE t_organisms
            Set
                organism = _orgName,
                organism_db_name = _orgDBName,
                description = _orgDescription,
                short_name = _orgShortName,
                storage_location = _orgStorageLocation,
                storage_url = _orgStorageURL,
                domain = _orgDomain,
                kingdom = _orgKingdom,
                phylum = _orgPhylum,
                class = _orgClass,
                order = _orgOrder,
                family = _orgFamily,
                genus = _orgGenus,
                species = _orgSpecies,
                strain = _orgStrain,
                active = _orgActive,
                newt_id_list = _newtIDList,
                ncbi_taxonomy_id = _ncbiTaxonomyID,
                auto_define_taxonomy = _autoDefineTaxonomyFlag
            WHERE organism_id = _id;

            -- If _callingUser is defined, update entered_by in t_organisms_change_history
            If char_length(_callingUser) > 0 Then
                CALL public.alter_entered_by_user ('public', 't_organisms_change_history', 'organism_id', _id, _callingUser, _message => _alterEnteredByMessage);
            End If;

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Organism %s', _exceptionMessage, _orgName);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_NEWT_IDs;
END
$$;

COMMENT ON PROCEDURE public.add_update_organisms IS 'AddUpdateOrganisms';
