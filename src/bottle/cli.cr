require "ydl_binaries"

require "./config"
require "./styles"
require "./version"

require "../glue/song"


class CLI

  # layout:
  # [[shortflag, longflag], key, type]
  @options = [
    [["-h", "--help"], "help", "bool"],
    [["-v", "--version"], "version", "bool"],
    [["-i", "--install"], "install", "bool"],
    [["-s", "--song"], "song", "string"],
    [["-a", "--artist"], "artist", "string"]
  ]


  @args : Hash(String, String)

  def initialize(argv : Array(String))
    @args = parse_args(argv)
  end

  def version
    puts "irs v#{IRS::VERSION}"
  end

  def help
    msg = <<-EOP
    #{Style.bold "Usage: irs [-h] [-v] [-i] [-s <song> -a <artist>]"}

    #{Style.bold "Arguments:"}
        #{Style.blue "-h, --help"}              Show this help message and exit
        #{Style.blue "-v, --version"}           Show the program version and exit
        #{Style.blue "-i, --install"}           Download ffmpeg and youtube_dl binaries to #{Style.green Config.binary_location}
        #{Style.blue "-s, --song <song>"}       Specify song name for downloading
        #{Style.blue "-a, --artist <artist>"}   Specify artist name for downloading

    #{Style.bold "Examples:"}
        $ #{Style.green %(irs --song "Bohemian Rhapsody" --artist "Queen")}
        #{Style.dim %(# => downloads the song "Bohemian Rhapsody" by "Queen")}
        $ #{Style.green %(irs --album "Demon Days" --artist "Gorillaz")}
        #{Style.dim %(# => downloads the album "Demon Days" by "Gorillaz")}

    #{Style.bold "This project is licensed under the MIT license."}
    #{Style.bold "Project page: <github.com/cooperhammond/irs>"}
    EOP

    puts msg
  end

  def act_on_args
    if @args["help"]? || @args.keys.size == 0
      help
      exit
    elsif @args["version"]?
      version
      exit
    elsif @args["install"]?
      YdlBinaries.get_both(Config.binary_location)
      exit
    elsif @args["song"]? && @args["artist"]?
      s = Song.new(@args["song"], @args["artist"])
      s.provide_client_keys("e4198f6a3f7b48029366f22528b5dc66", "ba057d0621a5496bbb64edccf758bde5")
      s.grab_it()
      exit
    end
  end

  private def parse_args(argv : Array(String)) : Hash(String, String)
    arguments = {} of String => String

    i = 0
    current_key = ""
    pass_next_arg = false
    argv.each do |arg|

      # If the previous arg was an arg flag, this is an arg, so pass it
      if pass_next_arg 
        pass_next_arg = false
        i += 1
        next 
      end

      flag = [] of Array(String) | String
      valid_flag = false

      @options.each do |option|
        if option[0].includes?(arg)
          flag = option
          valid_flag = true
          break
        end
      end

      # ensure the flag is actually defined
      if !valid_flag
        arg_error argv, i, %("#{arg}" is an invalid flag or argument.)
      end

      # ensure there's an argument if the program needs one
      if flag[2] == "string" && i + 1 > argv.size
        arg_error argv, i, %("#{arg}" needs an argument.)
      end

      
      key = flag[1].as(String)
      if flag[2] == "string"
        arguments[key] = argv[i + 1]
        pass_next_arg = true
      elsif flag[2] == "bool"
        arguments[key] = "true"
      end

      i += 1
    end

    return arguments
  end

  private def arg_error(argv : Array(String), arg : Int32, msg : String) : Nil
    precursor = "irs "

    start = argv[..arg - 1]
    last = argv[arg + 1..]

    distance = (precursor + start.join(" ")).size

    print Style.dim(precursor + start.join(" "))
    print Style.bold(Style.red(" " + argv[arg]).to_s)
    puts Style.dim (" " + last.join(" "))

    (0..distance).each do |i|
      print " "
    end
    puts "^"

    puts Style.red(Style.bold(msg).to_s)
    puts "Type `irs -h` to see usage."
    exit 1
  end
end