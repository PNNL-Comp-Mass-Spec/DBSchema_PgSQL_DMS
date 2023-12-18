--
-- Name: store_job_psm_stats(integer, real, real, integer, integer, integer, integer, integer, integer, integer, integer, real, integer, integer, integer, integer, real, real, integer, integer, integer, integer, real, real, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_job_psm_stats(IN _job integer, IN _msgfthreshold real, IN _fdrthreshold real, IN _spectrasearched integer, IN _totalpsms integer, IN _uniquepeptides integer, IN _uniqueproteins integer, IN _totalpsmsfdrfilter integer DEFAULT 0, IN _uniquepeptidesfdrfilter integer DEFAULT 0, IN _uniqueproteinsfdrfilter integer DEFAULT 0, IN _msgfthresholdisevalue integer DEFAULT 0, IN _percentmsnscansnopsm real DEFAULT 0, IN _maximumscangapadjacentmsn integer DEFAULT 0, IN _uniquephosphopeptidecountfdr integer DEFAULT 0, IN _uniquephosphopeptidesctermk integer DEFAULT 0, IN _uniquephosphopeptidesctermr integer DEFAULT 0, IN _missedcleavageratio real DEFAULT 0, IN _missedcleavageratiophospho real DEFAULT 0, IN _trypticpeptides integer DEFAULT 0, IN _keratinpeptides integer DEFAULT 0, IN _trypsinpeptides integer DEFAULT 0, IN _dynamicreporterion integer DEFAULT 0, IN _percentpsmsmissingntermreporterion real DEFAULT 0, IN _percentpsmsmissingreporterion real DEFAULT 0, IN _uniqueacetylpeptidesfdr integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the PSM stats in t_analysis_job_psm_stats for the specified analysis job
**
**  Arguments:
**    _job                                  Job number
**    _msgfThreshold                        MS-GF SpecProb or E-Value threshold
**    _fdrThreshold                         FDR threshold
**    _spectraSearched                      Number of spectra that were searched
**    _totalPSMs                            Stats based on _msgfThreshold (Number of identified spectra)
**    _uniquePeptides                       Stats based on _msgfThreshold
**    _uniqueProteins                       Stats based on _msgfThreshold
**    _totalPSMsFDRFilter                   Stats based on _fdrThreshold  (Number of identified spectra)
**    _uniquePeptidesFDRFilter              Stats based on _fdrThreshold
**    _uniqueProteinsFDRFilter              Stats based on _fdrThreshold
**    _msgfThresholdIsEValue                When 1, _msgfThreshold is actually an E-Value
**    _percentMSnScansNoPSM                 Percent (between 0 and 100) measuring the percent of MSn scans that did not have a filter passing PSM
**    _maximumScanGapAdjacentMSn            Maximum number of scans separating two MS2 spectra with search results; large gaps indicates that a processing thread in MSGF+ crashed and the results may be incomplete
**    _uniquePhosphopeptideCountFDR         Number of Phosphopeptides (any S, T, or Y that is phosphorylated); filtered using _fdrThreshold
**    _uniquePhosphopeptidesCTermK          Number of Phosphopeptides with K on the C-terminus
**    _uniquePhosphopeptidesCTermR          Number of Phosphopeptides with R on the C-terminus
**    _missedCleavageRatio                  Value between 0 and 1; computed as the number of unique peptides with a missed cleavage / number of unique peptides
**    _missedCleavageRatioPhospho           Value between 0 and 1; like _missedCleavageRatio but for phosphopeptides
**    _trypticPeptides                      Number of tryptic peptides (partially or fully tryptic)
**    _keratinPeptides                      Number of peptides from Keratin
**    _trypsinPeptides                      Number of peptides from Trypsin
**    _dynamicReporterIon                   Set to 1 if TMT (or iTRAQ) was a dynamic modification, e.g. MSGFPlus_PartTryp_DynMetOx_TMT_6Plex_Stat_CysAlk_20ppmParTol.txt
**    _percentPSMsMissingNTermReporterIon   When _dynamicReporterIon is 1, the percent of PSMs that have an N-terminus without TMT; value between 0 and 100
**    _percentPSMsMissingReporterIon        When _dynamicReporterIon is 1, the percent of PSMs that have an N-terminus or a K without TMT; value between 0 and 100
**    _uniqueAcetylPeptidesFDR              Number of peptides with any acetylated K; filtered using _fdrThreshold
**    _infoOnly                             When true, preview updates
**    _message                              Status message
**    _returnCode                           Return code
**
**  Auth:   mem
**  Date:   02/21/2012 mem - Initial version
**          05/08/2012 mem - Added _fdrThreshold, _totalPSMsFDRFilter, _uniquePeptidesFDRFilter, and _uniqueProteinsFDRFilter
**          01/17/2014 mem - Added _msgfThresholdIsEValue
**          01/21/2016 mem - Added _percentMSnScansNoPSM and _maximumScanGapAdjacentMSn
**          09/28/2016 mem - Added three _uniquePhosphopeptide parameters, two _missedCleavageRatio parameters, and _trypticPeptides, _keratinPeptides, and _trypsinPeptides
**          07/15/2020 mem - Added _dynamicReporterIon, _percentPSMsMissingNTermReporterIon, and _percentPSMsMissingReporterIon
**          07/15/2020 mem - Added _uniqueAcetylPeptidesFDR
**          12/17/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job                                := Coalesce(_job, 0);

    _infoOnly                           := Coalesce(_infoOnly, false);
    _fdrThreshold                       := Coalesce(_fdrThreshold, 1);
    _msgfThresholdIsEValue              := Coalesce(_msgfThresholdIsEValue, 0);

    _percentMSnScansNoPSM               := Coalesce(_percentMSnScansNoPSM, 0);
    _maximumScanGapAdjacentMSn          := Coalesce(_maximumScanGapAdjacentMSn,0);

    _uniquePhosphopeptideCountFDR       := Coalesce(_uniquePhosphopeptideCountFDR, 0);
    _uniquePhosphopeptidesCTermK        := Coalesce(_uniquePhosphopeptidesCTermK, 0);
    _uniquePhosphopeptidesCTermR        := Coalesce(_uniquePhosphopeptidesCTermR, 0);
    _missedCleavageRatio                := Coalesce(_missedCleavageRatio, 0);
    _missedCleavageRatioPhospho         := Coalesce(_missedCleavageRatioPhospho, 0);

    _trypticPeptides                    := Coalesce(_trypticPeptides, 0);
    _keratinPeptides                    := Coalesce(_keratinPeptides, 0);
    _trypsinPeptides                    := Coalesce(_trypsinPeptides, 0);

    _dynamicReporterIon                 := Coalesce(_dynamicReporterIon, 0);
    _percentPSMsMissingNTermReporterIon := Coalesce(_percentPSMsMissingNTermReporterIon, 0);
    _percentPSMsMissingReporterIon      := Coalesce(_percentPSMsMissingReporterIon, 0);

    _uniqueAcetylPeptidesFDR            := Coalesce(_uniqueAcetylPeptidesFDR, 0);

    ---------------------------------------------------
    -- Make sure _job is defined in t_analysis_job
    ---------------------------------------------------

    If Not Exists (SELECT job FROM t_analysis_job WHERE job = _job) Then
        _message := format('Analysis job not found in t_analysis_job: %s', _job);
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-14s %-13s %-24s %-16s %-15s %-20s %-20s %-14s %-19s %-19s %-24s %-29s %-15s %-23s %-23s %-25s %-29s %-16s %-16s %-16s %-15s %-20s %-39s %-33s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'MSGF_Threshold',
                            'FDR_Threshold',
                            'MSGF_Threshold_Is_EValue',
                            'Spectra_Searched',
                            'Total_PSMs_MSGF',
                            'Unique_Peptides_MSGF',
                            'Unique_Proteins_MSGF',
                            'Total_PSMs_FDR',
                            'Unique_Peptides_FDR',
                            'Unique_Proteins_FDR',
                            'Percent_MSn_Scans_No_PSM',
                            'Maximum_Scan_Gap_Adjacent_MSn',
                            'Phosphopeptides',
                            'CTerm_K_Phosphopeptides',
                            'CTerm_R_Phosphopeptides',
                            'Missed_Cleavage_Ratio_FDR',
                            'Missed_Cleavage_Ratio_Phospho',
                            'Tryptic_Peptides',
                            'Keratin_Peptides',
                            'Trypsin_Peptides',
                            'Acetyl_Peptides',
                            'Dynamic_Reporter_Ion',
                            'Percent_PSMs_Missing_NTerm_Reporter_Ion',
                            'Percent_PSMs_Missing_Reporter_Ion'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------',
                                     '-------------',
                                     '------------------------',
                                     '----------------',
                                     '---------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------',
                                     '-------------------',
                                     '-------------------',
                                     '------------------------',
                                     '-----------------------------',
                                     '---------------',
                                     '-----------------------',
                                     '-----------------------',
                                     '-------------------------',
                                     '-----------------------------',
                                     '----------------',
                                     '----------------',
                                     '----------------',
                                     '---------------',
                                     '--------------------',
                                     '---------------------------------------',
                                     '---------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        _infoData := format(_formatSpecifier,
                            _job,
                            _msgfThreshold,
                            _fdrThreshold,
                            _msgfThresholdIsEValue,
                            _spectraSearched,
                            _totalPSMs,
                            _uniquePeptides,
                            _uniqueProteins,
                            _totalPSMsFDRFilter,
                            _uniquePeptidesFDRFilter,
                            _uniqueProteinsFDRFilter,
                            _percentMSnScansNoPSM,
                            _maximumScanGapAdjacentMSn,
                            _uniquePhosphopeptideCountFDR,
                            _uniquePhosphopeptidesCTermK,
                            _uniquePhosphopeptidesCTermR,
                            _missedCleavageRatio,
                            _missedCleavageRatioPhospho,
                            _trypticPeptides,
                            _keratinPeptides,
                            _trypsinPeptides,
                            _uniqueAcetylPeptidesFDR,
                            _dynamicReporterIon,
                            _percentPSMsMissingNTermReporterIon,
                            _percentPSMsMissingReporterIon
                          );

        RAISE INFO '%', _infoData;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_analysis_job_psm_stats using a MERGE statement
    -----------------------------------------------

    MERGE INTO t_analysis_job_psm_stats AS target
    USING ( SELECT _job AS Job,
                   _msgfThreshold AS MSGF_Threshold,
                   _fdrThreshold AS FDR_Threshold,
                   _msgfThresholdIsEValue AS MSGF_Threshold_Is_EValue,
                   _spectraSearched AS Spectra_Searched,
                   _totalPSMs AS Total_PSMs_MSGF,
                   _uniquePeptides AS Unique_Peptides_MSGF,
                   _uniqueProteins AS Unique_Proteins_MSGF,
                   _totalPSMsFDRFilter AS Total_PSMs_FDR,
                   _uniquePeptidesFDRFilter AS Unique_Peptides_FDR,
                   _uniqueProteinsFDRFilter AS Unique_Proteins_FDR,
                   _percentMSnScansNoPSM AS Percent_MSn_Scans_No_PSM,
                   _maximumScanGapAdjacentMSn AS Maximum_Scan_Gap_Adjacent_MSn,
                   _missedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
                   _trypticPeptides AS Tryptic_Peptides_FDR,
                   _keratinPeptides AS Keratin_Peptides_FDR,
                   _trypsinPeptides AS Trypsin_Peptides_FDR,
                   _uniqueAcetylPeptidesFDR AS Acetyl_Peptides_FDR,
                   _dynamicReporterIon AS Dynamic_Reporter_Ion,
                   _percentPSMsMissingNTermReporterIon AS Percent_PSMs_Missing_NTerm_Reporter_Ion,
                   _percentPSMsMissingReporterIon AS Percent_PSMs_Missing_Reporter_Ion
          ) AS Source
    ON (target.job = Source.job)
    WHEN MATCHED THEN
        UPDATE SET
            MSGF_Threshold                          = Source.MSGF_Threshold,
            FDR_Threshold                           = Source.FDR_Threshold,
            MSGF_Threshold_Is_EValue                = Source.MSGF_Threshold_Is_EValue,
            Spectra_Searched                        = Source.Spectra_Searched,
            Total_PSMs                              = Source.Total_PSMs_MSGF,
            Unique_Peptides                         = Source.Unique_Peptides_MSGF,
            Unique_Proteins                         = Source.Unique_Proteins_MSGF,
            Total_PSMs_FDR_Filter                   = Source.Total_PSMs_FDR,
            Unique_Peptides_FDR_Filter              = Source.Unique_Peptides_FDR,
            Unique_Proteins_FDR_Filter              = Source.Unique_Proteins_FDR,
            Percent_MSn_Scans_No_PSM                = Source.Percent_MSn_Scans_No_PSM,
            Maximum_Scan_Gap_Adjacent_MSn           = Source.Maximum_Scan_Gap_Adjacent_MSn,
            Missed_Cleavage_Ratio_FDR               = Source.Missed_Cleavage_Ratio_FDR,
            Tryptic_Peptides_FDR                    = Source.Tryptic_Peptides_FDR,
            Keratin_Peptides_FDR                    = Source.Keratin_Peptides_FDR,
            Trypsin_Peptides_FDR                    = Source.Trypsin_Peptides_FDR,
            Acetyl_Peptides_FDR                     = Source.Acetyl_Peptides_FDR,
            Dynamic_Reporter_Ion                    = Source.Dynamic_Reporter_Ion,
            Percent_PSMs_Missing_NTerm_Reporter_Ion = Source.Percent_PSMs_Missing_NTerm_Reporter_Ion,
            Percent_PSMs_Missing_Reporter_Ion       = Source.Percent_PSMs_Missing_Reporter_Ion,
            Last_Affected                           = CURRENT_TIMESTAMP

    WHEN NOT MATCHED THEN
        INSERT (Job,
                MSGF_Threshold,
                FDR_Threshold,
                MSGF_Threshold_Is_EValue,
                Spectra_Searched,
                Total_PSMs,
                Unique_Peptides,
                Unique_Proteins,
                Total_PSMs_FDR_Filter,
                Unique_Peptides_FDR_Filter,
                Unique_Proteins_FDR_Filter,
                Percent_MSn_Scans_No_PSM,
                Maximum_Scan_Gap_Adjacent_MSn,
                Missed_Cleavage_Ratio_FDR,
                Tryptic_Peptides_FDR,
                Keratin_Peptides_FDR,
                Trypsin_Peptides_FDR,
                Acetyl_Peptides_FDR,
                Dynamic_Reporter_Ion,
                Percent_PSMs_Missing_NTerm_Reporter_Ion,
                Percent_PSMs_Missing_Reporter_Ion,
                Last_Affected)
        VALUES (Source.Job,
                Source.MSGF_Threshold,
                Source.FDR_Threshold,
                Source.MSGF_Threshold_Is_EValue,
                Source.Spectra_Searched,
                Source.Total_PSMs_MSGF,
                Source.Unique_Peptides_MSGF,
                Source.Unique_Proteins_MSGF,
                Source.Total_PSMs_FDR,
                Source.Unique_Peptides_FDR,
                Source.Unique_Proteins_FDR,
                Source.Percent_MSn_Scans_No_PSM,
                Source.Maximum_Scan_Gap_Adjacent_MSn,
                Source.Missed_Cleavage_Ratio_FDR,
                Source.Tryptic_Peptides_FDR,
                Source.Keratin_Peptides_FDR,
                Source.Trypsin_Peptides_FDR,
                Source.Acetyl_Peptides_FDR,
                Source.Dynamic_Reporter_Ion,
                Source.Percent_PSMs_Missing_NTerm_Reporter_Ion,
                Source.Percent_PSMs_Missing_Reporter_Ion,
                CURRENT_TIMESTAMP);

    If _uniquePhosphopeptideCountFDR = 0 Then
        -----------------------------------------------
        -- No phosphopeptide results for this job
        -- Make sure t_analysis_job_psm_stats_phospho does not have this job
        -----------------------------------------------

        DELETE FROM t_analysis_job_psm_stats_phospho
        WHERE job = _job;
    Else
        -----------------------------------------------
        -- Add/Update t_analysis_job_psm_stats_phospho using a MERGE statement
        -----------------------------------------------

        MERGE INTO t_analysis_job_psm_stats_phospho AS target
        USING ( SELECT _job AS Job,
                       _uniquePhosphopeptideCountFDR AS Phosphopeptides,
                       _uniquePhosphopeptidesCTermK AS CTerm_K_Phosphopeptides,
                       _uniquePhosphopeptidesCTermR AS CTerm_R_Phosphopeptides,
                       _missedCleavageRatioPhospho AS MissedCleavageRatio
              ) AS Source
        ON (target.job = Source.job)
        WHEN MATCHED THEN
            UPDATE SET
                Phosphopeptides        = Source.Phosphopeptides,
                CTerm_K_Phosphopeptides = Source.CTerm_K_Phosphopeptides,
                CTerm_R_Phosphopeptides = Source.CTerm_R_Phosphopeptides,
                Missed_Cleavage_Ratio    = Source.MissedCleavageRatio,
                Last_Affected          = CURRENT_TIMESTAMP

        WHEN NOT MATCHED THEN
            INSERT (Job,
                    Phosphopeptides,
                    CTerm_K_Phosphopeptides,
                    CTerm_R_Phosphopeptides,
                    Missed_Cleavage_Ratio,
                    Last_Affected)
            VALUES (Source.Job,
                    Source.Phosphopeptides,
                    Source.CTerm_K_Phosphopeptides,
                    Source.CTerm_R_Phosphopeptides,
                    Source.MissedCleavageRatio,
                    CURRENT_TIMESTAMP);

    End If;

    _message := 'PSM stats storage successful';

    If char_length(_message) > 0 And _infoOnly Then
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.store_job_psm_stats(IN _job integer, IN _msgfthreshold real, IN _fdrthreshold real, IN _spectrasearched integer, IN _totalpsms integer, IN _uniquepeptides integer, IN _uniqueproteins integer, IN _totalpsmsfdrfilter integer, IN _uniquepeptidesfdrfilter integer, IN _uniqueproteinsfdrfilter integer, IN _msgfthresholdisevalue integer, IN _percentmsnscansnopsm real, IN _maximumscangapadjacentmsn integer, IN _uniquephosphopeptidecountfdr integer, IN _uniquephosphopeptidesctermk integer, IN _uniquephosphopeptidesctermr integer, IN _missedcleavageratio real, IN _missedcleavageratiophospho real, IN _trypticpeptides integer, IN _keratinpeptides integer, IN _trypsinpeptides integer, IN _dynamicreporterion integer, IN _percentpsmsmissingntermreporterion real, IN _percentpsmsmissingreporterion real, IN _uniqueacetylpeptidesfdr integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_job_psm_stats(IN _job integer, IN _msgfthreshold real, IN _fdrthreshold real, IN _spectrasearched integer, IN _totalpsms integer, IN _uniquepeptides integer, IN _uniqueproteins integer, IN _totalpsmsfdrfilter integer, IN _uniquepeptidesfdrfilter integer, IN _uniqueproteinsfdrfilter integer, IN _msgfthresholdisevalue integer, IN _percentmsnscansnopsm real, IN _maximumscangapadjacentmsn integer, IN _uniquephosphopeptidecountfdr integer, IN _uniquephosphopeptidesctermk integer, IN _uniquephosphopeptidesctermr integer, IN _missedcleavageratio real, IN _missedcleavageratiophospho real, IN _trypticpeptides integer, IN _keratinpeptides integer, IN _trypsinpeptides integer, IN _dynamicreporterion integer, IN _percentpsmsmissingntermreporterion real, IN _percentpsmsmissingreporterion real, IN _uniqueacetylpeptidesfdr integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_job_psm_stats(IN _job integer, IN _msgfthreshold real, IN _fdrthreshold real, IN _spectrasearched integer, IN _totalpsms integer, IN _uniquepeptides integer, IN _uniqueproteins integer, IN _totalpsmsfdrfilter integer, IN _uniquepeptidesfdrfilter integer, IN _uniqueproteinsfdrfilter integer, IN _msgfthresholdisevalue integer, IN _percentmsnscansnopsm real, IN _maximumscangapadjacentmsn integer, IN _uniquephosphopeptidecountfdr integer, IN _uniquephosphopeptidesctermk integer, IN _uniquephosphopeptidesctermr integer, IN _missedcleavageratio real, IN _missedcleavageratiophospho real, IN _trypticpeptides integer, IN _keratinpeptides integer, IN _trypsinpeptides integer, IN _dynamicreporterion integer, IN _percentpsmsmissingntermreporterion real, IN _percentpsmsmissingreporterion real, IN _uniqueacetylpeptidesfdr integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'StoreJobPSMStats';

