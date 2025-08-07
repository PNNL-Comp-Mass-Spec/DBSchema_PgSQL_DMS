--
-- Name: get_cc_service_type(text, text, text, text, integer, text, text, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_cc_service_type(_datasetname text, _experimentname text, _campaignname text, _datasettypename text, _datasetratingid integer, _instrumentname text, _instrumentgroupname text, _acqlengthminutes integer, _separationtypename text, _separationgroupname text, _sampletypename text) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determines the cost center service type for the given set of metadata
**
**      Service types (tracked via table cc.t_service_type):
**
**      ID     Service Type                         Description
**      --     ------------                         -----------
**      0      Undefined                            Undefined
**      1      None                                 Not a cost center tracked requested run or dataset
**      25     Ambiguous                            Unable to auto-determine the correct service type
**      100    Peptides: Short Advanced MS          Astral, nanoPOTS, timsTOF SCP, separation time <= 60 minutes
**      101    Peptides: Short Standard MS          HFX, Lumos, Eclipse, Exploris, SRM, MRM, separation time <= 60 minutes
**      102    Peptides: Long Advanced MS           Astral, nanoPOTS, timsTOF SCP, separation time > 60 minutes
**      103    Peptides: Long Standard MS           HFX, Lumos, Eclipse, Exploris, separation time > 60 minutes
**      104    MALDI                                MALDI (run count = hr count)
**      110    Peptides: Screening MS               All Orbitraps, separation time <= 5 minutes (ultra fast), or infusion
**      111    Lipids                               Lipids
**      112    Metabolites                          Metabolites
**      113    GC-MS                                GC-MS
**
**  Arguments:
**    _datasetName              Dataset name (ignored if an empty string)
**    _experimentName           Experiment name
**    _campaignName             Campaign name
**    _datasetTypeName          Dataset type name
**    _datasetRatingID          Dataset rating ID (see t_dataset_rating_name)
**    _instrumentName           Instrument name
**    _instrumentGroupName      Instrument group name
**    _acqLengthMinutes         Acquisition time, in minutes (only available for datasets, not requested runs)
**    _separationTypeName       Separation type name
**    _separationGroupName      Separation group name
**    _sampleTypeName           Sample type name (see t_secondary_sep_sample_type and sample_type_id in t_secondary_sep)
**
**  Logic:
**      - If dataset rating is -5 or -4 (Not Released), this function returns service_type 1 (None)
**      - If the dataset rating is -1 (No Data aka Blank/Bad),                            service_type is 1 (None)
**      - If the experiment name is 'Blank' or the experiment's campaign is 'Blank',      service_type is 1 (None)
**      - If the campaign name is QC_Mammalian, QC-Standard, or QC-Shew-Standard,         service_type is 1 (None)
**      - If the dataset name or experiment name starts with QC_Mam, QC_Metab, QC_Shew, or QC_BTLE, service_type is 1
**      - If the dataset type is MRM, service_type is 101
**      - If the instrument group contains GC, service_type is 113
**      - If the instrument group is Agilent_QQQ, service_type is 113
**      - If the dataset type contains GC or is EI-HMS, service_type is 113
**      - If the dataset type contains MALDI, service_type is 104
**      - If the instrument group contains MALDI or is QExactive_Imaging, service_type is 104 (this includes MALDI_timsTOF_Imaging)
**      - If the instrument group is timsTOF_Flex, service_type is 104
**      - If instrument group is timsTOF_SCP, service_type is 100 or 102, depending on separation time (<= 60 minutes or > 60)
**      - If sample_type for the separation type is Lipids, service_type is 111
**      - If sample_type for the separation type is Metabolites, service_type is 112
**      - If sample_type for the separation type is Glycans, service_type is 103 (long standard peptides)
**      - If acquisition time is 5 minutes or shorter, type is 110
**      - If separation_type name or separation group name has "-NanoPot", service_type is 100 or 102, depending on separation time (<= 60 minutes or > 60)
**      - If instrument group is Astral and separation time is > 60 minutes, service_type is 102
**      - If instrument group is Astral and separation time is <= 60 minutes, service_type is 100
**      - If instrument group is Ascend, Eclipse, Exploris, Lumos, QEHFX, QExactive, VelosOrbi and separation time is > 60 minutes, service_type is 103
**      - If instrument group is Ascend, Eclipse, Exploris, Lumos, QEHFX, QExactive, VelosOrbi and separation time is <= 60 minutes, service_type is 101
**      - Otherwise, set service_type to Ambiguous
**
**  Example usage:
**      SELECT *
**      FROM get_cc_service_type (
**           _datasetName => 'QC_Mam_23_01_R08_27June25_Monty_ES906_1602_70SPD',
**           _experimentName => 'QC_Mam_23_01',
**           _campaignName => 'QC_Mammalian',
**           _datasetTypeName => 'DIA-HMS-HCD-HMSn',
**           _datasetRatingID => 5,
**           _instrumentName => 'Astral01',
**           _instrumentGroupName => 'Astral',
**           _acqLengthMinutes => 14,
**           _separationTypeName => 'LC-Neo-Formic_20Min',
**           _separationGroupName => 'LC-Formic_20min',
**           _sampleTypeName => 'Peptides'
**      );
**
**      SELECT *
**      FROM get_cc_service_type (
**           _datasetName => 'MoTrPAC_HM_CompRef_Plex01_G_f18_18Jan23_Bart_BEH-CoA-23-11-12',
**           _experimentName => 'MoTrPAC_HM_CompRef_Plex01_G_f18',
**           _campaignName => 'MoTrPAC',
**           _datasetTypeName => 'HMS-HCD-HMSn',
**           _datasetRatingID => 5,
**           _instrumentName => 'Exploris02',
**           _instrumentGroupName => 'Exploris',
**           _acqLengthMinutes => 120,
**           _separationTypeName => 'LC-Dionex-Formic_2hr',
**           _separationGroupName => 'LC-Formic_2hr ',
**           _sampleTypeName => 'Peptides'
**      );
**
**  Auth:   mem
**  Date:   06/28/2025 mem - Initial release
**          07/19/2025 mem - Return service type ID 1 (None) when the dataset type is 'DataFiles' or 'Tracking'
**          07/31/2025 mem - Change service type IDs to range from 100 to 107 instead of 2 to 9
**                         - Use > 60 instead of >= 60 when differentiating between "short" or "long" peptide ID
**          08/06/2025 mem - Change service type IDs (MALDI is now 104, Peptide Screening is now 110, Lipids is now 111, Metabolites is new at 112, GC-MS is now 113)
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _dataset citext;
    _experiment citext;
    _campaign citext;
    _datasetType citext;
    _instrument citext;
    _instrumentGroup citext;
    _sampleType citext;
    _separationType citext;
    _separationGroup citext;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
    _returnCode text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName         := Trim(Coalesce(_datasetName, ''));
    _experimentName      := Trim(Coalesce(_experimentName, ''));
    _campaignName        := Trim(Coalesce(_campaignName, ''));
    _datasetTypeName     := Trim(Coalesce(_datasetTypeName, ''));
    _datasetRatingID     := Coalesce(_datasetRatingID, 0);
    _instrumentName      := Trim(Coalesce(_instrumentName, ''));
    _instrumentGroupName := Trim(Coalesce(_instrumentGroupName, ''));
    _acqLengthMinutes    := Coalesce(_acqLengthMinutes, 0);
    _separationTypeName  := Trim(Coalesce(_separationTypeName, ''));
    _separationGroupName := Trim(Coalesce(_separationGroupName, ''));
    _sampleTypeName      := Trim(Coalesce(_sampleTypeName, ''));

    _logErrors := true;

    ---------------------------------------------------
    -- Initialize the citext versions of several names
    ---------------------------------------------------

    _dataset         := _datasetName;
    _experiment      := _experimentName;
    _campaign        := _campaignName;
    _datasetType     := _datasetTypeName;
    _instrument      := _instrumentName;
    _instrumentGroup := _instrumentGroupName;
    _separationType  := _separationTypeName;
    _separationGroup := _separationGroupName;
    _sampleType      := _sampleTypeName;

    ---------------------------------------------------
    -- Lookup sample type name if not defined, but separation type is defined
    ---------------------------------------------------

    If _sampleType = '' And _separationType <> '' Then
        SELECT SST.name
        INTO _sampleType
        FROM t_secondary_sep SS
             INNER JOIN t_secondary_sep_sample_type SST
               ON SS.sample_type_id = SST.sample_type_id
        WHERE separation_type = _separationType;

        _sampleType := Trim(Coalesce(_sampleType, ''));
    End If;

    ---------------------------------------------------
    -- Determine the service type ID
    ---------------------------------------------------

    -- Check for a dataset rating of 'Not Released' or 'Not released (allow analysis)'
    If _datasetRatingID IN (-4, -5) Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for a dataset rating of 'No Data (Blank/Bad)'
    If _datasetRatingID = -1 Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for a dataset associated with an External instrument
    If _instrument LIKE 'External%' Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for the 'Blank' experiment or 'Blank' campaign
    If _experiment = 'Blank' OR _campaign = 'Blank' Then
        RETURN 1;       -- Service type: None
    End If;

    If _experimentName <> '' And _campaignName = '' Then
        -- Lookup the campaign for the experiment
        SELECT C.campaign
        INTO _campaign
        FROM t_experiments E
             INNER JOIN t_campaign C
               ON E.campaign_id = C.campaign_id
        WHERE experiment = _experiment;

        If FOUND And _campaign = 'Blank' Then
            RETURN 1;       -- Service type: None
        End If;

        _campaign := Coalesce(_campaign, '');
    End If;

    -- Check for a QC campaign
    If _campaign IN ('QC_Mammalian', 'QC-Standard', 'QC-Shew-Standard') Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for dataset name or experiment name starting with a QC sample type name
    If _dataset    LIKE 'QC_Mam%'   OR
       _experiment LIKE 'QC_Mam%'   OR
       _dataset    LIKE 'QC_Metab%' OR
       _experiment LIKE 'QC_Metab%' OR
       _dataset    LIKE 'QC_Shew%'  OR
       _experiment LIKE 'QC_Shew%'  OR
       _dataset    LIKE 'QC_BTLE%'  OR
       _experiment LIKE 'QC_BTLE%'  OR
    Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for a data package based dataset (which has dataset type 'DataFiles') or a tracking dataset
    If _datasetType IN ('DataFiles', 'Tracking') Then
        RETURN 1;       -- Service type: None
    End If;

    -- Check for an MRM (aka SRM) dataset
    If _datasetType = 'MRM' Then
        RETURN 101;       -- Peptides: Short standard MS
    End If;

    -- Check for a GC instrument group
    If _instrumentGroup LIKE '%GC%' OR _instrumentGroup = 'Agilent_QQQ' Then
        RETURN 113;       -- GC-MS
    End If;

    -- Check for a GC dataset
    If _datasetType LIKE '%GC%' OR _datasetType = 'EI-HMS' Then
        RETURN 113;       -- GC-MS
    End If;

    -- Check for a MALDI dataset
    If _datasetType LIKE '%MALDI%' Then
        RETURN 104;       -- MALDI
    End If;

    -- Check for a MALDI instrument group (this includes MALDI_timsTOF_Imaging)
    If _instrumentGroup LIKE '%MALDI%' OR _instrumentGroup = 'QExactive_Imaging' Then
        RETURN 104;       -- MALDI
    End If;

    -- Check for the timsTOF_Flex instrument group
    If _instrumentGroup = 'timsTOF_Flex' Then
        RETURN 104;       -- MALDI
    End If;

    -- Check for the timsTOF_SCP instrument group
    If _instrumentGroup = 'timsTOF_SCP' Then
        If _acqLengthMinutes <= 60 Then
            RETURN 100;   -- Peptides: Short advanced MS
        Else
            RETURN 102;   -- Peptides: Long advanced MS
        End If;
    End If;

    -- Check for an unrecognized timsTOF instrument group
    If _instrumentGroup LIKE '%timsTOF%' Then
        RETURN 25;      -- Ambiguous
    End If;

    -- Check for a lipid sample
    If _sampleType IN ('Lipids') Then
        RETURN 111;       -- Lipids
    End If;

    -- Check for a metabolite sample
    If _sampleType IN ('Metabolites') Then
        RETURN 112;       -- Metabolites
    End If;

    -- Check for a glycan sample
    If _sampleType IN ('Glycans') Then
        RETURN 103;       -- Peptides: Long Standard MS
    End If;

    -- Check for an undefined acquisition length
    If _acqLengthMinutes <= 0 Then
        RETURN 25;      -- Ambiguous
    End If;

    -- Check for short datasets
    If _acqLengthMinutes <= 5 Then
        RETURN 110;       -- Peptides: Screening MS
    End If;

    -- Check for NanoPots datasets
    If _separationType LIKE '%NanoPot%' OR _separationGroup LIKE '%NanoPot%' Then
        If _acqLengthMinutes <= 60 Then
            RETURN 100;   -- Peptides: Short Advanced MS
        Else
            RETURN 102;   -- Peptides: Long Advanced MS
        End If;
    End If;

    -- Check for Astral datasets
    If _instrumentGroup LIKE '%Astral%' Then
        If _acqLengthMinutes <= 60 Then
            RETURN 100;   -- Peptides: Short Advanced MS
        Else
            RETURN 102;   -- Peptides: Long Advanced MS
        End If;
    End If;

    -- Check for Orbitrap datasets
    If _instrumentGroup IN ('Ascend', 'Eclipse', 'Exploris', 'Lumos', 'QEHFX', 'QExactive', 'VelosOrbi') Then
        If _acqLengthMinutes <= 60 Then
            RETURN 101;   -- Peptides: Short Standard MS
        Else
            RETURN 103;   -- Peptides: Long Standard MS
        End If;
    End If;

    ---------------------------------------------------
    -- None of the criteria were matched, return service type 25
    ---------------------------------------------------

    RETURN 25; -- Ambiguous

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    If _logErrors Then
        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);
    Else
        _message := _exceptionMessage;
    End If;

    If Coalesce(_returnCode, '') = '' Then
        _returnCode := _sqlState;
    End If;

    If Position(_returnCode In _message) = 0 Then
        _message := format('%s (%s)', _message, _returnCode);
    End If;

    RAISE WARNING '%', _message;

    RETURN 25; -- Ambiguous
END
$$;


ALTER FUNCTION public.get_cc_service_type(_datasetname text, _experimentname text, _campaignname text, _datasettypename text, _datasetratingid integer, _instrumentname text, _instrumentgroupname text, _acqlengthminutes integer, _separationtypename text, _separationgroupname text, _sampletypename text) OWNER TO d3l243;

