--
-- Name: get_psutil_cpu(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision) RETURNS record
    LANGUAGE plpythonu SECURITY DEFINER
    AS $$

from os import getloadavg
from psutil import cpu_times_percent, cpu_percent, cpu_count
from threading import Thread

class GetCpuPercentThread(Thread):
    def __init__(self, interval_seconds):
        self.interval_seconds = interval_seconds
        self.cpu_utilization_info = None
        super(GetCpuPercentThread, self).__init__()

    def run(self):
        self.cpu_utilization_info = cpu_percent(self.interval_seconds)

t = GetCpuPercentThread(0.5)
t.start()

ct = cpu_times_percent(0.5)
la = getloadavg()

t.join()

return t.cpu_utilization_info, la[0] / cpu_count(), la[0], la[1] / cpu_count(), la[1], ct.user, ct.system, ct.idle, ct.iowait, ct.irq + ct.softirq, ct.steal + ct.guest + ct.guest_nice

$$;


ALTER FUNCTION public.get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_psutil_cpu(OUT cpu_utilization double precision, OUT load_1m_norm double precision, OUT load_1m double precision, OUT load_5m_norm double precision, OUT load_5m double precision, OUT "user" double precision, OUT system double precision, OUT idle double precision, OUT iowait double precision, OUT irqs double precision, OUT other double precision) TO pgwatch2;

