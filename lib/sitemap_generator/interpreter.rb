require 'sitemap_generator'

module SitemapGenerator

  # Provide a class for evaluating blocks, making the URL helpers from the framework
  # and API methods available to it.
  class Interpreter

    if SitemapGenerator.app.rails3?
      include ::Rails.application.routes.url_helpers
    elsif SitemapGenerator.app.rails?
      require 'action_controller'
      include ActionController::UrlWriter
    end

    # Call with a block to evaluate a dynamic config.  The only method exposed for you is
    # `add` to add a link to the sitemap object attached to this interpreter.
    #
    # === Options
    # * <tt>link_set</tt> - a LinkSet instance to use.  Default is SitemapGenerator::Sitemap.
    #
    # All other options are passed to the LinkSet by setting them using accessor methods.
    def initialize(opts={}, &block)
      opts.reverse_merge!(:link_set => SitemapGenerator::Sitemap)
      @linkset = opts.delete :link_set
      puts "*** in initialize: opts = #{opts.inspect}"
      opts.each_pair do |key, value|
        case key.downcase 
        when "verbose"
          @linkset.verbose = (value.first.downcase == "t" ? true : false)
        end
      end
      # @linkset.send(:set_options, opts)
      eval(&block) if block_given?
    end

    def add(*args)
      @linkset.add(*args)
    end

    # Start a new group of sitemaps.  Any of the options to SitemapGenerator.new may
    # be passed.  Pass a block with calls to +add+ to add links to the sitemaps.
    #
    # All groups use the same sitemap index.
    def group(*args, &block)
      @linkset.group(*args, &block)
    end

    # Evaluate the block in the interpreter.  Pass :yield_sitemap => true to
    # yield the Interpreter instance to the block...for old-style calling.
    def eval(opts={}, &block)
      if block_given?
        if opts[:yield_sitemap]
          yield self
        else
          instance_eval(&block)
        end
      end
    end

    # Run the interpreter on a config file using
    # the default <tt>SitemapGenerator::Sitemap</tt> sitemap object.
    #
    # === Options
    # * <tt>:config_file</tt> - full path to the config file to evaluate.
    #   Default is config/sitemap.rb in your application's root directory.
    # All other options are passed to +new+.
    def self.run(opts={}, &block)
      config_file = opts.delete(:config_file)
      config_file ||= SitemapGenerator.app.root + 'config/sitemap.rb'
      interpreter = self.new(opts)
      interpreter.instance_eval(File.read(config_file), config_file.to_s)
      interpreter
    end
  end
end
