require 'foreman/engine'
require 'fileutils'

module ForemanMonit
  class Exporter
    def initialize(options)
      @app = options[:app]
      @user = options[:user]
      @target = options[:target]
      @env = options[:env]
      @chruby = options[:chruby]
      @rubyver = options[:rubyver]
      @rvm = options[:rvm]

      @procfile = options[:procfile]

      @su = which_su
      @sudo = which_sudo
      @sudo_opts = "#{@sudo} -H -n -E"
      @bash = which_bash
      

      @engine = Foreman::Engine.new
      load_procfile
      load_env
      @port = @engine.base_port
    end

    def run!
      Dir.mkdir(@target) unless File.exist?(@target)
      FileUtils.rm Dir.glob("#{@target}/*.conf")
      @engine.each_process do |name, process|
        file_name = File.join(@target, "#{@app}-#{name}.conf")
        File.open(file_name, 'w') { |f| f.write ERB.new(File.read(File.expand_path('../../../templates/monitrc.erb', __FILE__)), nil, '-').result(binding) }
      end
    end

    def info
      puts @engine.processes.inspect
    end

    def port
      @port += 1
      @port-1
    end

    def chruby_init
      if @chruby
        "chruby #{@chruby} &&"
      else
        ''
      end
    end

    def rvm_prefix
      if @rubyver
        "#{rvm_path} #{@rubyver} do"
      else
        ''
      end
    end

    def base_dir
      Dir.getwd
    end

    def pid_file(name)
      File.expand_path(File.join(@target, "#{@app}-#{name}.pid"))
    end

    def log_file(name)
      File.expand_path(File.join(@target, "#{@app}-#{name}.log"))
    end

    def rails_env
      @env
    end

    private

    def which_su
      `which su`.chomp
    end

    def which_sudo
      `which sudo`.chomp
    end

    def which_bash
      bash = `which bash`.chomp
      if bash.empty?
        bash = '/bin/sh'
      end

      bash
    end

    def rvm_path
      @rvm || File.expand_path("~#{@user}/.rvm/bin/rvm")
    end

    def load_env
      default_env = File.join(@engine.root, '.env')
      @engine.load_env default_env if File.exists?(default_env)
    end

    def load_procfile
      @engine.load_procfile(@procfile)
    end
  end
end
