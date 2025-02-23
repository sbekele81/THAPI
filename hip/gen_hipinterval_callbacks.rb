require 'erb'
require 'yaml'

SRC_DIR = ENV['SRC_DIR'] || '.'
START = 'entry'
STOP = 'exit'

class DBT_event
  attr_reader :fields, :name_unsanitized, :fields_type

  def initialize(klass)
    #Should be named lltng
    @name_unsanitized = klass[:name]
    @fields = klass[:payload]
    @fields_type = @fields.map { |f| [f[:name], f[:cast_type]] }.to_h
  end

  def fields_name
    @fields.map { |f| f[:name] }
  end

  def field_type_by_name
  end

  #uuid
  def name
    @name_unsanitized.gsub(':', '_')
  end

  def name_striped
    # #{namespace}:#{foo}_#{START} -> #{foo}
    # #{namespace}:#{foo} -> #{foo}
    @name_unsanitized[/:(.*?)_?(?:#{START}|#{STOP})?$/, 1]
  end

  def callback_signature
    decls = []
    @fields.each do |f|
      decls.push ['size_t', "_#{f[:name]}_length"] if f[:class] == 'array_static'
      decls.push [f[:cast_type], f[:name]]
    end
    (['const bt_event *bt_evt', 'const bt_clock_snapshot *bt_clock'] + decls.map { |t, n| "#{t} #{n}" }).join(",\n    ")
  end
end

hip_babeltrace_model = YAML.load_file('hip_babeltrace_model.yaml')

$dbt_events = hip_babeltrace_model[:event_classes].map { |klass|
  DBT_event.new(klass)
}

template = File.read(File.join(SRC_DIR, "hipinterval_callbacks.cpp.erb"))
puts ERB.new(template).result(binding).gsub(/^\s*$\n/, '')
