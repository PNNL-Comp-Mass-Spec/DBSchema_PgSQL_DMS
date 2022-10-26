--
-- Name: get_mass_correction_id(double precision); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_mass_correction_id(_modmass double precision) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Gets Mass Correction ID for given mod mass, +/- 0.00006 Da
**
**  Return values: 0: failure, otherwise, MassCorrectionID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          04/02/2020 mem - Change _modMass from a varchar to a float
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _massCorrectionID int;
    _mcVariance float := 0.00006;
BEGIN
    SELECT mass_correction_id
    INTO _massCorrectionID
    FROM t_mass_correction_factors
    WHERE (monoisotopic_mass < _modMass + _mcVariance AND
           monoisotopic_mass > _modMass - _mcVariance);

    If FOUND Then
        RETURN _massCorrectionID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_mass_correction_id(_modmass double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_mass_correction_id(_modmass double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_mass_correction_id(_modmass double precision) IS 'GetMassCorrectionID';

