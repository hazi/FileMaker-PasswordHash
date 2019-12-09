require "unix_crypt"
require "base64"
require "logger"

class Crypt6fm < UnixCrypt::SHABase
  class << self
    # @param [Boolean] flag true の時 debug log を出力します
    def DEBUG=(flag)
      @debug = flag
    end

    def bit_specified_base64encode(input)
      Base64.strict_encode64(Digest::SHA512.digest(input)).tr("+", ".").tr("=", "")
    end

    protected

    # ロジックは UnixCrypt::SHABase と同じ。
    # デバッグ用の途中経過のログ出力用
    def internal_hash(password, salt, rounds = nil)
      rounds = apply_rounds_bounds(rounds || default_rounds)
      logging("SET rounds: #{rounds}")

      salt = salt[0..15]

      b = digest.digest("#{password}#{salt}#{password}")
      logging("SET b: #{password}#{salt}#{password}")
      logging("SET b (MD5): #{Digest::MD5.hexdigest(b).upcase}")

      a_string = password + salt + b * (password.length/length) + b[0...password.length % length]
      logging("SET a_string (MD5): #{Digest::MD5.hexdigest(a_string).upcase}")

      password_length = password.length
      while password_length > 0
        a_string += (password_length & 1 != 0) ? b : password
        password_length >>= 1
      end
      logging("SET a_string (MD5): #{Digest::MD5.hexdigest(a_string).upcase}")

      input = digest.digest(a_string)
      logging("SET input (MD5): #{Digest::MD5.hexdigest(input).upcase}")

      dp = digest.digest(password * password.length)
      logging("SET dp (MD5): #{Digest::MD5.hexdigest(dp).upcase}")
      p = dp * (password.length/length) + dp[0...password.length % length]
      logging("SET p (MD5): #{Digest::MD5.hexdigest(p).upcase}")

      ds = digest.digest(salt * (16 + input.bytes.first))
      logging("SET ds (MD5): #{Digest::MD5.hexdigest(ds).upcase}")

      s = ds * (salt.length/length) + ds[0...salt.length % length]
      logging("SET s (MD5): #{Digest::MD5.hexdigest(s).upcase}")

      rounds.times do |index|
        c_string = ((index & 1 != 0) ? p : input)
        c_string += s unless index % 3 == 0
        c_string += p unless index % 7 == 0
        c_string += ((index & 1 != 0) ? input : p)
        input = digest.digest(c_string)
      end
      logging("SET input (MD5): #{Digest::MD5.hexdigest(input).upcase}")

      input
    end

    def logging(log)
      return unless @debug

      @logger ||= logger
      path = caller()[0].sub("#{__dir__}/", "")
      @logger.debug("#{log} (#{path})")
    end

    def logger
      logger = Logger.new(STDOUT)
      logger.datetime_format = '%H:%M:%S.%06d'

      logger
    end

    def digest; Digest::SHA512; end
    def length; 64; end
    def identifier; "6f"; end
  end
end
