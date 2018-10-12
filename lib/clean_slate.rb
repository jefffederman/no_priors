require 'new_code'

class CleanSlate
  LINE_MATCH_REGEX = /^(?<filename>.+\.rb):(?<line_number>\d+)/

  attr_reader :offenses
  # takes a diff
  # for each new file
  # TODO: use Rubocop directly instead of CLI
  def initialize(diff)
    new_code = NewCode.new(diff)
    filenames = new_code.filenames
    @offenses = []
    rubocop_output = `rubocop #{filenames.join(' ')}`
    line_matches = rubocop_output.lines.grep(LINE_MATCH_REGEX)
    line_matches.each do |line|
      matches = line.match(LINE_MATCH_REGEX)
      filename = matches[:filename]
      line_number = matches[:line_number].to_i
      if new_code.files_and_lines[filename].include?(line_number)
        @offenses.push line
      end
    end
  end
end

# Old performance
# Measure Mode: wall_time
# Thread ID: 70237504671280
# Fiber ID: 70237514250220
# Total: 12.516168
# Sort by: self_time
#
#  %self      total      self      wait     child     calls  name
#  99.96     12.511    12.511     0.000     0.000       13   Kernel#`
#   0.01      0.001     0.001     0.000     0.000       13   String#lines
#   0.01      0.001     0.001     0.000     0.000      171   Regexp#match
#   0.00      0.001     0.001     0.000     0.000      586   String#match?
#   0.00      0.000     0.000     0.000     0.000      342   MatchData#[]
#   0.00     12.516     0.000     0.000    12.516       14  *Array#each
#   0.00      0.001     0.000     0.000     0.001      171   String#match
#   0.00      0.000     0.000     0.000     0.000      171   Array#include?
#   0.00      0.000     0.000     0.000     0.000      171   String#to_i
#   0.00      0.000     0.000     0.000     0.000       52   Array#push
#   0.00     12.516     0.000     0.000    12.516        1   CleanSlate#initialize

# That's super slow :/
# Let's see how long Rubocopping all the files at once takes...
# ❯❯❯ time rubocop $(git diff master --name-only *.rb)
# rubocop $(git diff master --name-only *.rb)  0.99s user 0.32s system 75% cpu 1.719 total

# Hmmm, Rubocop appears to run in constant time regardless of number of files.
# Let's process them all at once instead!

# New performance
# Measure Mode: wall_time
# Thread ID: 70143304797720
# Fiber ID: 70143306165840
# Total: 0.950475
# Sort by: self_time
#
#  %self      total      self      wait     child     calls  name
#  99.80      0.949     0.949     0.000     0.000        1   Kernel#`
#   0.05      0.000     0.000     0.000     0.000      502   Regexp#===
#   0.04      0.002     0.000     0.000     0.001        2   Array#each
#   0.03      0.000     0.000     0.000     0.000      171   Regexp#match
#   0.02      0.000     0.000     0.000     0.000        1   String#lines
#   0.02      0.000     0.000     0.000     0.000      342   MatchData#[]
#   0.01      0.950     0.000     0.000     0.950        1   CleanSlate#initialize
#   0.01      0.000     0.000     0.000     0.000      171   Array#include?
#   0.01      0.000     0.000     0.000     0.000      171   String#match
#   0.00      0.000     0.000     0.000     0.000      171   String#to_i
#   0.00      0.000     0.000     0.000     0.000       52   Array#push
#   0.00      0.001     0.000     0.000     0.001        1   Enumerable#grep
#   0.00      0.000     0.000     0.000     0.000        1   Array#join
