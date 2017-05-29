#
# Description: quicklook build logs using [fpp](https://facebook.github.io/PathPicker/)
# Author: xu-cheng
# Usage:
#   brew build-logs <formula>
#

fpp = which("fpp")
abort "Please install fpp with `brew instal fpp`." unless fpp

logd = begin
  ARGV.resolved_formulae.first.logs
rescue
  HOMEBREW_LOGS/ARGV.named.first
end
abort "#{logd} doesn't exist." unless logd.directory?

exec "find #{logd} | #{fpp}"
