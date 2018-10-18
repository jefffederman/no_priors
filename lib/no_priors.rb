require 'no_priors/new_code'
require 'open3'

class NoPriors
  LINE_MATCH_REGEX = /^(?<filename>[^:]+):(?<line_number>\d+)/

  attr_reader :offenses

  # TODO: consider using Rubocop directly instead of CLI if faster
  def initialize(diff)
    new_code = NewCode.new(diff)
    filenames = new_code.filenames
    @offenses = []
    rc_out_str, _rc_err_str, _status = Open3.capture3 \
      'rubocop',
      filenames.join(' ')
    line_matches = rc_out_str.lines.grep(LINE_MATCH_REGEX)
    collect_offenses(new_code, line_matches)
  rescue Errno::ENOENT => e
    puts e.message + '. Please install rubocop.'
  end

  private

  attr_reader :new_code, :line_matches

  def collect_offenses(new_code, line_matches)
    return unless offenses.empty?

    line_matches.each do |line|
      matches = line.match(LINE_MATCH_REGEX)
      filename = matches[:filename]
      line_number = matches[:line_number].to_i
      if new_code.files_and_lines.fetch(filename, []).include?(line_number)
        @offenses.push line
      end
    end
  end
end
