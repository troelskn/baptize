module Baptize
  module Plugins

    module Verifications
      def fail_verification
        raise VerificationFailure.new
      end
    end

  end
end
