enum LogLevel
  All   = 0
  Trace = 1
  Debug = 2
  Info  = 3
  Warn  = 4
  Error = 5
  Fatal = 6
  Off   = 7
end

class Invidious::LogHandler < Kemal::BaseLogHandler

  METRIC_MEAUSREMENT = "invidious"

  def initialize(@io : IO = STDOUT, @level = LogLevel::Debug, @metric_io : IO? = nil)
  end

  def record_metric(tags : Array({String, String}), fields : Array({String, Float64}))
    @metric_io.try do |metric_io|
      metric_io << METRIC_MEAUSREMENT
      tags.each do |key, value|
        metric_io << ","
        metric_io << "#{key}=#{value}"
      end
      metric_io << " "
      first = true
      fields.each do |key, value|
        metric_io << "," unless first
        metric_io << "#{key}=#{value}"
        first = false
      end
      metric_io << "\n"
      metric_io.flush
    end
  end

  def call(context : HTTP::Server::Context)
    elapsed_time = Time.measure { call_next(context) }
    elapsed_text = elapsed_text(elapsed_time)

    info("#{context.response.status_code} #{context.request.method} #{context.request.resource} #{elapsed_text}")

    main_resource = context.request.resource.gsub(/\?.*/, "").gsub(/(\/api\/v1\/[a-z]+).*/, "\\1").gsub(/(\/api\/manifest\/[a-z]+).*/, "\\1")
    tags = [{"status_code", "#{context.response.status_code}"}, {"method", "#{context.request.method}"}, {"resource", main_resource}]
    fields = [{"latency", elapsed_time.total_milliseconds}]
    record_metric(tags, fields)

    context
  end

  def puts(message : String)
    @io << message << '\n'
    @io.flush
  end

  def write(message : String)
    @io << message
    @io.flush
  end

  def set_log_level(level : String)
    @level = LogLevel.parse(level)
  end

  def set_log_level(level : LogLevel)
    @level = level
  end

  {% for level in %w(trace debug info warn error fatal) %}
    def {{level.id}}(message : String)
      if LogLevel::{{level.id.capitalize}} >= @level
        puts("#{Time.utc} [{{level.id}}] #{message}")
      end
    end
  {% end %}

  private def elapsed_text(elapsed)
    millis = elapsed.total_milliseconds
    return "#{millis.round(2)}ms" if millis >= 1

    "#{(millis * 1000).round(2)}µs"
  end
end
