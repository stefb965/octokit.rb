module Octokit
  class Client
    module Users

      # List all GitHub users
      #
      # This provides a dump of every user, in the order that they signed up
      # for GitHub.
      #
      # @param options [Hash] Optional options.
      # @option options [Integer] :since The integer ID of the last User that
      #   you’ve seen.
      #
      # @see http://developer.github.com/v3/users/#get-all-users
      #
      # @return [Array] List of GitHub users.
      def all_users(options={})
        get "users", options
      end

      # Get a single user
      #
      # @param user [String] A GitHub user name.
      # @return [Hashie::Mash]
      # @see http://developer.github.com/v3/users/#get-a-single-user
      # @example
      #   Octokit.user("sferik")
      def user(user=nil)
        if user
          get "users/#{user}"
        else
          get 'user'
        end
      end

      # Retrieve the access_token.
      #
      # @param code [String] Authorization code generated by GitHub.
      # @param app_id [String] Client Id we received when our application was registered with GitHub.
      # @param app_secret [String] Client Secret we received when our application was registered with GitHub.
      # @return [Hashie::Mash] Hash holding the access token.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/oauth/#web-application-flow
      # @example
      #   @client.access_token('aaaa', 'xxxx', 'yyyy', {:accept => 'application/json'})
      def exchange_code_for_token(code, app_id = client_id, app_secret = client_secret, options = {})
        options.merge!({
          :code => code,
          :client_id => app_id,
          :client_secret => app_secret
        })
        post("#{web_endpoint}/login/oauth/access_token", options)
      end

      # Validate user username and password
      #
      # @param options [Hash] User credentials
      # @option options [String] :login GitHub login
      # @option options [String] :password GitHub password
      # @return [Boolean] True if credentials are valid
      def validate_credentials(options = {})
        !self.class.new(options).user.nil?
      rescue Octokit::Unauthorized
        false
      end

      # Update the authenticated user
      #
      # @param options [Hash] A customizable set of options.
      # @option options [String] :name
      # @option options [String] :email Publically visible email address.
      # @option options [String] :blog
      # @option options [String] :company
      # @option options [String] :location
      # @option options [Boolean] :hireable
      # @option options [String] :bio
      # @return [Hashie::Mash]
      # @example
      #   Octokit.user(:name => "Erik Michaels-Ober", :email => "sferik@gmail.com", :company => "Code for America", :location => "San Francisco", :hireable => false)
      def update_user(options)
        patch("user", options)
      end

      # Get a user's followers.
      #
      # @param user [String] Username of the user whose list of followers you are getting.
      # @return [Array<Hashie::Mash>] Array of hashes representing users followers.
      # @see http://developer.github.com/v3/users/followers/#list-followers-of-a-user
      # @example
      #   Octokit.followers('pengwynn')
      def followers(user=login, options={})
        get("users/#{user}/followers", options)
      end

      # Get list of users a user is following.
      #
      # @param user [String] Username of the user who you are getting the list of the people they follow.
      # @return [Array<Hashie::Mash>] Array of hashes representing users a user is following.
      # @see  http://developer.github.com/v3/users/followers/#list-users-following-another-user
      # @example
      #   Octokit.following('pengwynn')
      def following(user=login, options={})
        get("users/#{user}/following", options)
      end

      # Check if you are following a user.
      #
      # Requries an authenticated client.
      #
      # @param user [String] Username of the user that you want to check if you are following.
      # @return [Boolean] True if you are following the user, false otherwise.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/followers/#check-if-you-are-following-a-user
      # @example
      #   @client.follows?('pengwynn')
      def follows?(*args)
        target = args.pop
        user = args.first
        user ||= login
        return if user.nil?
        boolean_from_response(:get, "user/following/#{target}")
      end

      # Follow a user.
      #
      # Requires authenticatied client.
      #
      # @param user [String] Username of the user to follow.
      # @return [Boolean] True if follow was successful, false otherwise.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/followers/#follow-a-user
      # @example
      #   @client.follow('holman')
      def follow(user, options={})
        boolean_from_response(:put, "user/following/#{user}", options)
      end

      # Unfollow a user.
      #
      # Requires authenticated client.
      #
      # @param user [String] Username of the user to unfollow.
      # @return [Boolean] True if unfollow was successful, false otherwise.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/followers/#unfollow-a-user
      # @example
      #   @client.unfollow('holman')
      def unfollow(user, options={})
        boolean_from_response(:delete, "user/following/#{user}", options)
      end

      # Get list of repos starred by a user.
      #
      # @param user [String] Username of the user to get the list of their starred repositories.
      # @param options [Hash] Optional options
      # @option options [String] :sort (created) Sort: <tt>created</tt> or <tt>updated</tt>.
      # @option options [String] :direction (desc) Direction: <tt>asc</tt> or <tt>desc</tt>.
      # @return [Array<Hashie::Mash>] Array of hashes representing repositories starred by user.
      # @see http://developer.github.com/v3/repos/starring/#list-repositories-being-starred
      # @example
      #   Octokit.starred('pengwynn')
      def starred(user=login, options={})
        path = user_authenticated? ? "/user/starred" : "/users/#{user}/starred"
        paginate(path, options)
      end

      # Check if you are starring a repo.
      #
      # Requires authenticated client.
      #
      # @param user [String] Username of repository owner.
      # @param repo [String] Name of the repository.
      # @return [Boolean] True if you are following the repo, false otherwise.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/repos/starring/#check-if-you-are-starring-a-repository
      # @example
      #   @client.starred?('pengwynn', 'octokit')
      def starred?(user, repo, options={})
        boolean_from_response(:get, "user/starred/#{user}/#{repo}", options)
      end

      # Get a public key.
      #
      # Note, when using dot notation to retrieve the values, ruby will return
      # the hash key for the public keys value instead of the actual value, use
      # symbol or key string to retrieve the value. See example.
      #
      # Requires authenticated client.
      #
      # @param key_id [Integer] Key to retreive.
      # @return [Hashie::Mash] Hash representing the key.
      # @see http://developer.github.com/v3/users/keys/#get-a-single-public-key
      # @example
      #   @client.key(1)
      # @example Retrieve public key contents
      #   public_key = @client.key(1)
      #   public_key.key
      #   # => Error
      #
      #   public_key[:key]
      #   # => "ssh-rsa AAA..."
      #
      #   public_key['key']
      #   # => "ssh-rsa AAA..."
      def key(key_id, options={})
        get("user/keys/#{key_id}", options)
      end

      # Get list of public keys for user.
      #
      # Requires authenticated client.
      #
      # @return [Array<Hashie::Mash>] Array of hashes representing public keys.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/keys/#list-your-public-keys
      # @example
      #   @client.keys
      def keys(options={})
        paginate("user/keys", options)
      end

      # Get list of public keys for user.
      #
      # Requires authenticated client.
      #
      # @return [Array<Hashie::Mash>] Array of hashes representing public keys.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/keys/#list-public-keys-for-a-user
      # @example
      #   @client.user_keys('pengwynn'
      def user_keys(user, options={})
        # TODO: Roll this into .keys
        paginate("users/#{user}/keys", options)
      end

      # Add public key to user account.
      #
      # Requires authenticated client.
      #
      # @param title [String] Title to give reference to the public key.
      # @param key [String] Public key.
      # @return [Hashie::Mash] Hash representing the newly added public key.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/keys/#create-a-public-key
      # @example
      #   @client.add_key('Personal projects key', 'ssh-rsa AAA...')
      def add_key(title, key, options={})
        post("user/keys", options.merge({:title => title, :key => key}))
      end

      # Update a public key
      #
      # Requires authenticated client
      #
      # @param key_id [Integer] Id of key to update.
      # @param options [Hash] Hash containing attributes to update.
      # @option options [String] :title
      # @option options [String] :key
      # @return [Hashie::Mash] Hash representing the updated public key.
      # @see http://developer.github.com/v3/users/keys/#update-a-public-key
      # @example
      #   @client.update_key(1, :title => 'new title', :key => "ssh-rsa BBB")
      def update_key(key_id, options={})
        patch("/user/keys/#{key_id}", options)
      end

      # Remove a public key from user account.
      #
      # Requires authenticated client.
      #
      # @param id [String] Id of the public key to remove.
      # @return [Boolean] True if removal was successful, false otherwise.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/keys/#delete-a-public-key
      # @example
      #   @client.remove_key(1)
      def remove_key(id, options={})
        boolean_from_response(:delete, "user/keys/#{id}", options)
      end

      # List email addresses for a user.
      #
      # Requires authenticated client.
      #
      # @return [Array<String>] Array of email addresses.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/emails/#list-email-addresses-for-a-user
      # @example
      #   @client.emails
      def emails(options={})
        paginate("user/emails", options)
      end

      # Add email address to user.
      #
      # Requires authenticated client.
      #
      # @param email [String] Email address to add to the user.
      # @return [Array<String>] Array of all email addresses of the user.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/emails/#add-email-addresses
      # @example
      #   @client.add_email('new_email@user.com')
      def add_email(email, options={})
        post("user/emails", options.merge({:email => email}))
      end

      # Remove email from user.
      #
      # Requires authenticated client.
      #
      # @param email [String] Email address to remove.
      # @return [Array<String>] Array of all email addresses of the user.
      # @see Octokit::Client
      # @see http://developer.github.com/v3/users/emails/#delete-email-addresses
      # @example
      #   @client.remove_email('old_email@user.com')
      def remove_email(emails)
        emails = Array(emails)
        boolean_from_response(:delete, "user/emails", emails)
      end

      # List repositories being watched by a user.
      #
      # @param user [String] User's GitHub username.
      #
      # @return [Array<Hashie::Mashie>] Array of repositories.
      #
      # @see http://developer.github.com/v3/activity/watching/#list-repositories-being-watched
      #
      # @example
      #   @client.subscriptions("pengwynn")
      def subscriptions(user=login, options={})
        path = user_authenticated? ? "/user/subscriptions" : "/users/#{user}/subscriptions"
        paginate(path, options)
      end
      alias :watched :subscriptions

    end
  end
end
