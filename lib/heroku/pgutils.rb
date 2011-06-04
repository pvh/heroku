require 'heroku/pg_resolver'

module PgUtils
  include PGResolver

  def spinner(ticks)
    %w(/ - \\ |)[ticks % 4]
  end

  def display_info(label, info)
    display(format("%-12s %s", label, info))
  end

  def munge_fork_and_follow(addon)
    %w[fork follow].each do |opt|
      if index = args.index("--#{opt}")
        val = args.delete_at index+1
        args.delete_at index

        resolved = Resolver.new(val, config_vars)
        display resolved.message if resolved.message
        abort_with_database_list(val) unless resolved[:url]

        url = resolved[:url]
        db = HerokuPostgresql::Client.new(url).get_database
        db_plan = db[:plan]
        version = db[:postgresql_version]

        abort " !  You cannot fork a database unless it is currently available." unless db[:state] == "available"
        abort " !  PostgreSQL v#{version} cannot be #{opt}ed. Please upgrade to a newer version." if '8' == version.split(/\./).first
        addon_plan = addon.split(/:/)[1] || 'ronin'

        funin = ["ronin", "fugu"]
        if     funin.member?(addon_plan) &&  funin.member?(db_plan)
          # fantastic
        elsif  funin.member?(addon_plan) && !funin.member?(db_plan)
          abort " !  Cannot #{opt} a #{resolved[:name]} to a ronin or a fugu database."
        elsif !funin.member?(addon_plan) &&  funin.member?(db_plan)
          abort " !  Can only #{opt} #{resolved[:name]} to a ronin or a fugu database."
        elsif !funin.member?(addon_plan) && !funin.member?(db_plan)
          # even better!
        end

        args << "#{opt}=#{url}"
      end
    end
    return args
  end

end
