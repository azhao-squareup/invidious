class Invidious::Jobs::DumpGcStatsJob < Invidious::Jobs::BaseJob
  def begin
    loop do
      stats = GC.prof_stats
      tags = [] of {String, String}
      fields = [
        {"heap_size", stats.heap_size.to_f64},
        {"free_bytes", stats.free_bytes.to_f64},
        {"unmapped_bytes", stats.unmapped_bytes.to_f64},
        {"bytes_since_gc", stats.bytes_since_gc.to_f64},
        {"bytes_before_gc", stats.bytes_before_gc.to_f64},
        {"non_gc_bytes", stats.non_gc_bytes.to_f64},
        {"gc_no", stats.gc_no.to_f64},
        {"markers_m1", stats.markers_m1.to_f64},
        {"bytes_reclaimed_since_gc", stats.bytes_reclaimed_since_gc.to_f64},
      ]
      LOGGER.record_metric(tags, fields)
      sleep 10.seconds
      Fiber.yield
    end
  end
end
