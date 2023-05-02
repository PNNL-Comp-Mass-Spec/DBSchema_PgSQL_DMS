--
CREATE OR REPLACE PROCEDURE public.store_job_psm_stats
(
    _job int = 0,
    _msgfThreshold real,
    _fdrThreshold real = 1,
    _spectraSearched int,
    _totalPSMs int,
    _uniquePeptides int,
    _uniqueProteins int,
    _totalPSMsFDRFilter int = 0,
    _uniquePeptidesFDRFilter int = 0,
    _uniqueProteinsFDRFilter int = 0,
    _msgfThresholdIsEValue int = 0,
    _percentMSnScansNoPSM real = 0,
    _maximumScanGapAdjacentMSn int = 0,
    _uniquePhosphopeptideCountFDR int = 0,
    _uniquePhosphopeptidesCTermK int = 0,
    _uniquePhosphopeptidesCTermR int = 0,
    _missedCleavageRatio real = 0,
    _missedCleavageRatioPhospho real = 0,
    _trypticPeptides int = 0,
    _keratinPeptides int = 0,
    _trypsinPeptides int = 0,
    _dynamicReporterIon int = 0,
    _percentPSMsMissingNTermReporterIon real = 0,
    _percentPSMsMissingReporterIon real = 0,
    _uniqueAcetylPeptidesFDR int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the PSM stats in T_Analysis_Job_PSM_Stats for the specified analysis job
**
**  Arguments:
**    _spectraSearched                      Number of spectra that were searched
**    _totalPSMs                            Stats based on _msgfThreshold (Number of identified spectra)
**    _uniquePeptides                       Stats based on _msgfThreshold
**    _uniqueProteins                       Stats based on _msgfThreshold
**    _totalPSMsFDRFilter                   Stats based on _fdrThreshold  (Number of identified spectra)
**    _uniquePeptidesFDRFilter              Stats based on _fdrThreshold
**    _uniqueProteinsFDRFilter              Stats based on _fdrThreshold
**    _msgfThresholdIsEValue                Set to 1 if _msgfThreshold is actually an EValue
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
**
**  Auth:   mem
**  Date:   02/21/2012 mem - Initial version
**          05/08/2012 mem - Added _fdrThreshold, _totalPSMsFDRFilter, _uniquePeptidesFDRFilter, and _uniqueProteinsFDRFilter
**          01/17/2014 mem - Added _msgfThresholdIsEValue
**          01/21/2016 mem - Added _percentMSnScansNoPSM and _maximumScanGapAdjacentMSn
**          09/28/2016 mem - Added three _uniquePhosphopeptide parameters, two _missedCleavageRatio parameters, and _trypticPeptides, _keratinPeptides, and _trypsinPeptides
**          07/15/2020 mem - Added _dynamicReporterIon, _percentPSMsMissingNTermReporterIon, and _percentPSMsMissingReporterIon
**          07/15/2020 mem - Added _uniqueAcetylPeptidesFDR
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job := Coalesce(_job, 0);
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _fdrThreshold := Coalesce(_fdrThreshold, 1);
    _msgfThresholdIsEValue := Coalesce(_msgfThresholdIsEValue, 0);

    _percentMSnScansNoPSM := Coalesce(_percentMSnScansNoPSM, 0);
    _maximumScanGapAdjacentMSn := Coalesce(_maximumScanGapAdjacentMSn,0);

    _uniquePhosphopeptideCountFDR := Coalesce(_uniquePhosphopeptideCountFDR, 0);
    _uniquePhosphopeptidesCTermK := Coalesce(_uniquePhosphopeptidesCTermK, 0);
    _uniquePhosphopeptidesCTermR := Coalesce(_uniquePhosphopeptidesCTermR, 0);
    _missedCleavageRatio := Coalesce(_missedCleavageRatio, 0);
    _missedCleavageRatioPhospho := Coalesce(_missedCleavageRatioPhospho, 0);

    _trypticPeptides := Coalesce(_trypticPeptides, 0);
    _keratinPeptides := Coalesce(_keratinPeptides, 0);
    _trypsinPeptides := Coalesce(_trypsinPeptides, 0);

    _dynamicReporterIon := Coalesce(_dynamicReporterIon, 0);
    _percentPSMsMissingNTermReporterIon := Coalesce(_percentPSMsMissingNTermReporterIon, 0);
    _percentPSMsMissingReporterIon := Coalesce(_percentPSMsMissingReporterIon, 0);

    _uniqueAcetylPeptidesFDR := Coalesce(_uniqueAcetylPeptidesFDR, 0);

    ---------------------------------------------------
    -- Make sure _job is defined in t_analysis_job
    ---------------------------------------------------

    If NOT EXISTS (SELECT * FROM t_analysis_job where job = _job) Then
        _message := 'job not found in t_analysis_job: ' || _job::text;
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT _job AS Job,
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
               _percentMSnScansNoPSM AS Percent_MSn_Scans_NoPSM,
               _maximumScanGapAdjacentMSn AS Maximum_ScanGap_Adjacent_MSn,
               _uniquePhosphopeptideCountFDR AS Phosphopeptides,
               _uniquePhosphopeptidesCTermK AS CTermK_Phosphopeptides,
               _uniquePhosphopeptidesCTermR AS CTermR_Phosphopeptides,
               _missedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
               _missedCleavageRatioPhospho AS MissedCleavageRatioPhospho,
               _trypticPeptides AS Tryptic_Peptides,
               _keratinPeptides AS Keratin_Peptides,
               _trypsinPeptides AS Trypsin_Peptides,
               _uniqueAcetylPeptidesFDR as Acetyl_Peptides,
               _dynamicReporterIon AS Dynamic_Reporter_Ion,
               _percentPSMsMissingNTermReporterIon AS Percent_PSMs_Missing_NTermReporterIon,
               _percentPSMsMissingReporterIon AS Percent_PSMs_Missing_ReporterIon

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_analysis_job_psm_stats using a MERGE statement
    -----------------------------------------------
    --
    ;
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
                   _percentMSnScansNoPSM AS Percent_MSn_Scans_NoPSM,
                   _maximumScanGapAdjacentMSn AS Maximum_ScanGap_Adjacent_MSn,
                   _missedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
                   _trypticPeptides AS Tryptic_Peptides_FDR,
                   _keratinPeptides AS Keratin_Peptides_FDR,
                   _trypsinPeptides AS Trypsin_Peptides_FDR,
                   _uniqueAcetylPeptidesFDR AS Acetyl_Peptides_FDR,
                   _dynamicReporterIon AS Dynamic_Reporter_Ion,
                   _percentPSMsMissingNTermReporterIon AS Percent_PSMs_Missing_NTermReporterIon,
                   _percentPSMsMissingReporterIon AS Percent_PSMs_Missing_ReporterIon
          ) AS Source
    ON (target.job = Source.job)
    WHEN MATCHED THEN
        UPDATE SET
            MSGF_Threshold = Source.MSGF_Threshold,
            FDR_Threshold = Source.FDR_Threshold,
            MSGF_Threshold_Is_EValue = Source.MSGF_Threshold_Is_EValue,
            Spectra_Searched = Source.Spectra_Searched,
            Total_PSMs = Source.Total_PSMs_MSGF,
            Unique_Peptides = Source.Unique_Peptides_MSGF,
            Unique_Proteins = Source.Unique_Proteins_MSGF,
            Total_PSMs_FDR_Filter = Source.Total_PSMs_FDR,
            Unique_Peptides_FDR_Filter = Source.Unique_Peptides_FDR,
            Unique_Proteins_FDR_Filter = Source.Unique_Proteins_FDR,
            Percent_MSn_Scans_NoPSM = Source.Percent_MSn_Scans_NoPSM,
            Maximum_ScanGap_Adjacent_MSn = Source.Maximum_ScanGap_Adjacent_MSn,
            Missed_Cleavage_Ratio_FDR = Source.Missed_Cleavage_Ratio_FDR,
            Tryptic_Peptides_FDR = Source.Tryptic_Peptides_FDR,
            Keratin_Peptides_FDR = Source.Keratin_Peptides_FDR,
            Trypsin_Peptides_FDR = Source.Trypsin_Peptides_FDR,
            Acetyl_Peptides_FDR = Source.Acetyl_Peptides_FDR,
            Dynamic_Reporter_Ion = Source.Dynamic_Reporter_Ion,
            Percent_PSMs_Missing_NTermReporterIon = Source.Percent_PSMs_Missing_NTermReporterIon,
            Percent_PSMs_Missing_ReporterIon = Source.Percent_PSMs_Missing_ReporterIon,
            Last_Affected = CURRENT_TIMESTAMP

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
                Percent_MSn_Scans_NoPSM,
                Maximum_ScanGap_Adjacent_MSn,
                Missed_Cleavage_Ratio_FDR,
                Tryptic_Peptides_FDR,
                Keratin_Peptides_FDR,
                Trypsin_Peptides_FDR,
                Acetyl_Peptides_FDR,
                Dynamic_Reporter_Ion,
                Percent_PSMs_Missing_NTermReporterIon,
                Percent_PSMs_Missing_ReporterIon,
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
                Source.Percent_MSn_Scans_NoPSM,
                Source.Maximum_ScanGap_Adjacent_MSn,
                Source.Missed_Cleavage_Ratio_FDR,
                Source.Tryptic_Peptides_FDR,
                Source.Keratin_Peptides_FDR,
                Source.Trypsin_Peptides_FDR,
                Source.Acetyl_Peptides_FDR,
                Source.Dynamic_Reporter_Ion,
                Source.Percent_PSMs_Missing_NTermReporterIon,
                Source.Percent_PSMs_Missing_ReporterIon,
                CURRENT_TIMESTAMP);

    If _uniquePhosphopeptideCountFDR = 0 Then
        -----------------------------------------------
        -- No phosphopeptide results for this job
        -- Make sure t_analysis_job_psm_stats_phospho does not have this job
        -----------------------------------------------
        --
        DELETE FROM t_analysis_job_psm_stats_phospho
        WHERE job = _job;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    Else
        -----------------------------------------------
        -- Add/Update t_analysis_job_psm_stats_phospho using a MERGE statement
        -----------------------------------------------
        --

        MERGE INTO t_analysis_job_psm_stats_phospho AS target
        USING ( SELECT _job AS Job,
                       _uniquePhosphopeptideCountFDR AS Phosphopeptides,
                       _uniquePhosphopeptidesCTermK AS CTermK_Phosphopeptides,
                       _uniquePhosphopeptidesCTermR AS CTermR_Phosphopeptides,
                       _missedCleavageRatioPhospho AS MissedCleavageRatio
              ) AS Source
        ON (target.job = Source.job)
        WHEN MATCHED THEN
            UPDATE SET
                Phosphopeptides = Source.Phosphopeptides,
                CTermK_Phosphopeptides = Source.CTermK_Phosphopeptides,
                CTermR_Phosphopeptides = Source.CTermR_Phosphopeptides,
                MissedCleavageRatio = Source.MissedCleavageRatio,
                Last_Affected = CURRENT_TIMESTAMP

        WHEN NOT MATCHED THEN
            INSERT (Job,
                    Phosphopeptides,
                    CTermK_Phosphopeptides,
                    CTermR_Phosphopeptides,
                    MissedCleavageRatio,
                    Last_Affected)
            VALUES (Source.Job,
                    Source.Phosphopeptides,
                    Source.CTermK_Phosphopeptides,
                    Source.CTermR_Phosphopeptides,
                    Source.MissedCleavageRatio,
                    CURRENT_TIMESTAMP);

    End If;

    _message := 'PSM stats storage successful';

    If _returnCode <> '' Then
        If _message = '' Then
            _message := 'Error in StoreJobPSMStats';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        If Not _infoOnly Then
            Call post_log_entry ('Error', _message, 'StoreJobPSMStats');
        End If;
    End If;

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.store_job_psmstats IS 'StoreJobPSMStats';
