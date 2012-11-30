require 'net/ssh'
require 'net/ssh/multi'

######################################################################################
################## Detection of various command line options #########################
######################################################################################
options = {}

ARGV.options do |opts|
    opts.banner = "Usage: ruby pressh.rb -f {host files} -c command or ruby pressh.rb -h test1,test2 =c command"
    opts.on(:REQUIRED, '-f', '--file', "The environment to run this script against.") do |hosts|
        options[:hostsFile] = hosts
    end
    opts.on(:REQUIRED, '-h', '--hosts', "A command delimited list of hosts to run against.") do |hosts|
        options[:hosts] = hosts
    end
    opts.on(:REQUIRED, '-c', '--command', "Command to be executed on each server") do |command|
        options[:command] = command
    end

    opts.on_tail(:NONE, '-h', '--help', "Display this screen.") do |help|
        puts opts
        exit
    end
    begin
        opts.parse!
        unless options.include? :command
            throw Exception
        end
        if options.include? :hosts and options.include? :hostsFile
            throw Exception
        end
    rescue
        puts opts
        exit
    end
end

######################################################################################
############################### The Magic ############################################
######################################################################################
Net::SSH::Multi.start(:concurrent_connections => 10, :on_error => :warn) do |session|
    if options[:hostsFile]
        File.open(options[:hostsFile]) do |f|
            f.each_line do |line|
                session.use line
            end
        end
    else

        options[:hosts].split(',').each do |h|
            session.use h
        end
    end

    session.exec options[:command]

    session.loop
end
