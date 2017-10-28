# Description: an experimental extension to `brew style --fix`
# Author: Baptiste Fontaine
# Usage: brew fix <formula> [<formula> ...]
#
# Note: this is experimental, use it at your own risk!
#
# This is an extension to `brew style --fix` which runs more actions on the
# formula:
#  - remove any `require "formula"` at the top
#  - replace the stable checksum with a sha256 if it's not already one
#  - replace `system "make install"` with `system "make", "install"`
#  and a few more things.

class Pathname
  def write!(s)
    open("w") { |p| p.write(s) }
  end
end

class FormulaFixer
  def initialize(f)
    system "brew", "style", "--fix", f.full_name
    @f = f
    @source = @f.path.open(&:read)
  end

  def replace!(pattern, repl)
    @source.gsub!(pattern, repl)
  end

  def remove!(pattern)
    replace! pattern, ""
  end

  def write!
    @f.path.write! @source
  end

  def fix_common_https_urls
    [
      %r{github\.com/},
      %r{code\.google\.com/},
      %r{(?:www|ftp)\.gnu\.org/},
      /(?:(?:trac|tools|www)\.)?ietf\.org/,
      %r{(?:www\.)?gnupg\.org/},
      /wiki\.freedesktop\.org/,
      /packages\.debian\.org/,
      %r{[^/]*github\.io/},
      %r{[^/]*\.apache\.org},
      %r{fossies\.org/},
      %r{mirrors\.kernel\.org/},
      %r{([^/]*\.|)bintray\.com/},
      %r{tools\.ietf\.org/},
    ].each do |domain|
      replace!(%r{["']http://(#{domain})}, '"https://\\1')
    end
  end

  def fix_deps
    %w[git ruby].each do |dep|
      remove!(/^\s+depends_on\s+["']#{dep}["']\n+/)
    end

    { "mercurial" => ":hg", "gfortran" => ":fortran" }.each do |bad, good|
      good = "\"#{good}\"" unless good =~ /^:/
      replace!(/^(\s+depends_on)\s+["']#{bad}["']$/, "\\1 #{good}")
    end
  end

  def fix_checksum
    ([
      @f.stable,
      @f.devel,
      @f.head,
    ] + @f.resources + @f.patchlist.select(&:external?).map(&:resource)).compact.each do |r|
      fix_resource_checksum r
    end
  end

  def fix_resource_checksum(res)
    chk = res.checksum
    return if !chk || chk.hash_type == :sha256

    # from cmd/fetch
    download = res.fetch
    return unless download.file?

    replace!(/#{chk.hash_type} ["']#{chk.hexdigest}["']/,
             %Q(sha256 "#{download.sha256}"))
  end

  def fix_required
    remove!(/^require ["']formula["']\n+/)
  end

  def fix_make_install
    replace!(/^(\s+)system "make ([a-z]+)"$/, '\\1system "make", "\\2"')
  end

  def fix!
    fix_checksum
    fix_required
    fix_make_install
    fix_deps
    fix_common_https_urls
    write!
  end
end

ARGV.formulae.each do |f|
  FormulaFixer.new(f).fix!
end
