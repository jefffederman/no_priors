# no_priors
Run Rubocop on only your changed lines.

## Install
`gem install no_priors`

## Usage
```ruby
diff = `git diff --unified=0` # only returns changed lines, no context
np = NoPriors.new(diff)
np.offenses
```

## Motivation

I wanted the ability to only lint changed lines, since I didn't want PRs for relatively small fixes obscured by changes due to Rubocop offenses on other lines in the file.
