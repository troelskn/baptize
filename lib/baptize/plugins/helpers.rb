module Baptize
  module Plugins

    module Helpers

      def asset_path(asset)
        File.expand_path(File.join("assets", asset))
      end

      def md5_of_file(path, md5)
        remote_assert "test $(md5sum #{path.shellescape} | cut -f1 -d' ') = #{md5.shellescape}"
      end

      def escape_sed_arg(s)
        s.gsub("'", "'\\\\''").gsub("\n", '\n').gsub("/", "\\\\/").gsub('&', '\\\&')
      end

      def replace_text(pattern, replacement, path)
        remote_execute "sed -i 's/#{escape_sed_arg(pattern)}/#{escape_sed_arg(replacement)}/g' #{path.shellescape}"
      end

      def render(path, locals = {})
        require 'erb'
        require 'ostruct'
        ERB.new(File.read(path)).result(locals.kind_of?(Binding) ? locals : OpenStruct.new(locals).instance_eval { binding })
      end

    end

  end
end
