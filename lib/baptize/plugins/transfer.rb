require 'tempfile'

module Capistrano
  module Baptize
    module Plugins
      module Transfer
        def self.included(base)
          base.send :alias_method, :original_upload, :upload
          base.send :alias_method, :upload, :patched_upload
        end

        # Performs a two-step upload
        # File is first uploaded to /tmp/, then moved into place
        # Can optionally roll everything into a tarball
        # and may chmod the destination afterwards
        def patched_upload(from, to, options={}, &block)
          use_tarball = options.delete :tarball
          set_owner = options.delete :owner
          if use_tarball
            raise "Can't tarball streaming upload" if from.kind_of?(IO)
            exclude = use_tarball[:exclude] if (use_tarball.kind_of?(Hash) && use_tarball[:exclude])
            tar_options = exclude.map {|glob| "--exclude \"#{glob}\" " }.join('')
            tempfile = Dir::Tmpname.make_tmpname(['/tmp/baptize-', '.tar.gz'], nil)
            local_command = "cd #{from.shellescape} ; #{local_tar_bin} -zcf #{tempfile.shellescape} #{tar_options}."
            raise "Unable to tar #{from}" unless run_locally(local_command)
            destination = "/tmp/#{File.basename(tempfile)}"
          else
            destination = "/tmp/#{File.basename(Dir::Tmpname.make_tmpname('/tmp/baptize-', nil))}"
          end
          original_upload(tempfile || from, destination, options, &block)
          if use_tarball
            run "tar -zxf #{destination.shellescape} -C #{to.shellescape}"
            run "rm #{destination.shellescape}"
          else
            run "mv #{destination.shellescape} #{to.shellescape}"
          end
          if set_owner
            run "chown -R #{set_owner}:#{set_owner} #{to.shellescape}"
          end
          if tempfile
            File.delete tempfile
          end
        end

        protected
        def local_tar_bin
          (`uname` =~ /Darwin/ ? "COPYFILE_DISABLE=true /usr/bin/gnutar" : "tar")
        end
      end
    end
  end
end
