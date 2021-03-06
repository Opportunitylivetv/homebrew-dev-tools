#
# Description: run script for each formula
# Author: jacknagel
# Usage:
#   brew for-each-formula <ruby code>
# Example:
#   brew for-each-formula 'puts f.name'
#
# copied from https://github.com/jacknagel/dotfiles/blob/master/bin/brew-for-each-formula.rb
#

if ARGV.empty?
  puts "Usage:\n\tbrew for-each-formula <ruby code>"
  exit 1
end

require "formula"

# Need to eval here and we control the input
# rubocop:disable Security/Eval
# rubocop:disable Lint/UnusedBlockArgument
Formula.each { |f| eval(ARGV.first) }
# rubocop:enable Security/Eval
# rubocop:enable Lint/UnusedBlockArgument
