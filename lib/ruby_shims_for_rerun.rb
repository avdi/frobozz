# Ruby 3.* has deprecated and then removed the `.exists?` aliases for `.exist?`
# Patch for rerun until it is updated for Ruby 3 compat.
# See: https://github.com/alexch/rerun/pull/137

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
