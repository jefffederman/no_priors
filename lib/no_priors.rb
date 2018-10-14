require 'no_priors/new_code'

class NoPriors
  LINE_MATCH_REGEX = /^(?<filename>.+\.rb):(?<line_number>\d+)/

  attr_reader :offenses

  # TODO: consider using Rubocop directly instead of CLI if faster
  def initialize(diff)
    new_code = NewCode.new(diff)
    filenames = new_code.filenames
    @offenses = []
    rubocop_output = `rubocop #{filenames.join(' ')}`
    line_matches = rubocop_output.lines.grep(LINE_MATCH_REGEX)
    collect_offenses(new_code, line_matches)
  rescue Error::ENOENT => e
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
