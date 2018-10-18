# E.g.,
# diff = `git diff --unified=0 *.rb`
# new_code = NewCode.new(diff)
class NewCode
  CHANGED_FILE_REGEX = /^\+\+\+ b\/(.*)/
  UNIFIED_DIFF_REGEX = /@@ -\d+,?\d+? \+(\d+),?(\d+)?/
  # TODO: unified diff regex only handles two way diff,
  # but it's possible to have a three way diff, e.g.,
  # @@@ ... ... ... @@@, or a four way diff, e.g.,
  # @@@@ ... ... ... ... @@@@, etc.
  # See

  attr_reader :files_and_lines

  # `diff` is an object which responds to `#lines` and
  # returns an array of strings
  def initialize(diff)
    @diff = diff
    @curr_changed_file = nil
    @prev_changed_file = nil
    @changed_lines = []
    @files_and_lines = {}
    build
  end

  def filenames
    files_and_lines.keys
  end

  private

  attr_reader :diff, :prev_changed_file, :curr_changed_file, :changed_lines

  def build
    diff.lines.each_with_index do |line, i|
      if line.match? CHANGED_FILE_REGEX
        @curr_changed_file = line.match(CHANGED_FILE_REGEX)[1]
        record_info if prev_changed_file
        @prev_changed_file = curr_changed_file
        @curr_changed_file = nil
      elsif line.match? UNIFIED_DIFF_REGEX
        @changed_lines.concat line_numbers(line)
      elsif i == diff.lines.length - 1
        record_info if prev_changed_file
      end
    end
  end

  def record_info
    @files_and_lines[prev_changed_file] = changed_lines
    @changed_lines = []
    @previous_changed_file = nil
  end

  def line_numbers(line)
    unified_diff_data = line.match(UNIFIED_DIFF_REGEX)
    diff_start = unified_diff_data[1].to_i

    if unified_diff_data[2]
      line_count = unified_diff_data[2].to_i
      return [] if line_count.zero?
      diff_end = diff_start + line_count
    else
      diff_end = diff_start + 1
    end

    (diff_start...diff_end).to_a
  end
end
