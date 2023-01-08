# Ruby 3.* has deprecated and then removed the `.exists?` aliases for `.exist?`
# Patch for rerun until it is updated for Ruby 3 compat.
# See: https://github.com/alexch/rerun/pull/137

CURRENT_RERUN_VERSION = Gem::Specification.find_by_name("rerun").version.to_s
EXPECTED_RERUN_VERSION = "0.13.1"
if CURRENT_RERUN_VERSION != EXPECTED_RERUN_VERSION
  warn <<~END
    Hi! This warning is from #{__FILE__}
      The rerun gem version has changed. Please check if I'm still needed.
      If so, please update EXPECTED_RERUN_VERSION="#{CURRENT_RERUN_VERSION}"
      If not, please remove me! Thanks!
  END
end
module FileTest
  singleton_class.module_exec do
    alias_method :exists?, :exist?
  end
end

class File
  singleton_class.module_exec do
    alias_method :exists?, :exist?
  end
end
