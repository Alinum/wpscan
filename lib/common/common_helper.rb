# encoding: UTF-8

LIB_DIR              = File.expand_path(File.dirname(__FILE__) + '/..')
ROOT_DIR             = File.expand_path(LIB_DIR + '/..') # expand_path is used to get "wpscan/" instead of "wpscan/lib/../"
DATA_DIR             = ROOT_DIR + '/data'
CONF_DIR             = ROOT_DIR + '/conf'
CACHE_DIR            = ROOT_DIR + '/cache'
WPSCAN_LIB_DIR       = LIB_DIR + '/wpscan'
WPSTOOLS_LIB_DIR     = LIB_DIR + '/wpstools'
UPDATER_LIB_DIR      = LIB_DIR + '/updater'
COMMON_LIB_DIR       = LIB_DIR + '/common'
MODELS_LIB_DIR       = COMMON_LIB_DIR + '/models'
COLLECTIONS_LIB_DIR  = COMMON_LIB_DIR + '/collections'

LOG_FILE             = ROOT_DIR + '/log.txt'

# Plugins directories
COMMON_PLUGINS_DIR   = COMMON_LIB_DIR + '/plugins'
WPSCAN_PLUGINS_DIR   = WPSCAN_LIB_DIR + '/plugins' # Not used ATM
WPSTOOLS_PLUGINS_DIR = WPSTOOLS_LIB_DIR + '/plugins'

# Data files
PLUGINS_FILE        = DATA_DIR + '/plugins.txt'
PLUGINS_FULL_FILE   = DATA_DIR + '/plugins_full.txt'
PLUGINS_VULNS_FILE  = DATA_DIR + '/plugin_vulns.xml'
THEMES_FILE         = DATA_DIR + '/themes.txt'
THEMES_FULL_FILE    = DATA_DIR + '/themes_full.txt'
THEMES_VULNS_FILE   = DATA_DIR + '/theme_vulns.xml'
WP_VULNS_FILE       = DATA_DIR + '/wp_vulns.xml'
WP_VERSIONS_FILE    = DATA_DIR + '/wp_versions.xml'
LOCAL_FILES_FILE    = DATA_DIR + '/local_vulnerable_files.xml'
VULNS_XSD           = DATA_DIR + '/vuln.xsd'
WP_VERSIONS_XSD     = DATA_DIR + '/wp_versions.xsd'
LOCAL_FILES_XSD     = DATA_DIR + '/local_vulnerable_files.xsd'

WPSCAN_VERSION       = '2.1'

$LOAD_PATH.unshift(LIB_DIR)
$LOAD_PATH.unshift(WPSCAN_LIB_DIR)
$LOAD_PATH.unshift(MODELS_LIB_DIR)

def kali_linux?
  %x{uname -a}.match(/linux kali/i) ? true : false
end

require 'environment'

# TODO : add an exclude pattern ?
def require_files_from_directory(absolute_dir_path, files_pattern = '*.rb')
  files = Dir[File.join(absolute_dir_path, files_pattern)]

  # Files in the root dir are loaded first, then thoses in the subdirectories
  files.sort_by { |file| [file.count("/"), file] }.each do |f|
    f = File.expand_path(f)
    #puts "require #{f}" # Used for debug
    require f
  end
end

require_files_from_directory(COMMON_LIB_DIR, '**/*.rb')

# Add protocol
def add_http_protocol(url)
  url =~ /^https?:/ ? url : "http://#{url}"
end

def add_trailing_slash(url)
  url =~ /\/$/ ? url : "#{url}/"
end

# loading the updater
require_files_from_directory(UPDATER_LIB_DIR)
@updater = UpdaterFactory.get_updater(ROOT_DIR)

if @updater
  REVISION = @updater.local_revision_number()
else
  REVISION = 'NA'
end

# our 1337 banner
def banner
  puts '____________________________________________________'
  puts ' __          _______   _____                  '
  puts ' \\ \\        / /  __ \\ / ____|                 '
  puts '  \\ \\  /\\  / /| |__) | (___   ___  __ _ _ __  '
  puts '   \\ \\/  \\/ / |  ___/ \\___ \\ / __|/ _` | \'_ \\ '
  puts '    \\  /\\  /  | |     ____) | (__| (_| | | | |'
  puts "     \\/  \\/   |_|    |_____/ \\___|\\__,_|_| |_| v#{WPSCAN_VERSION}r#{REVISION}"
  puts
  puts '    WordPress Security Scanner by the WPScan Team'
  puts ' Twitter: @_WPScan_, @ethicalhack3r, @erwan_lr,'
  puts '          @gbrindisi, @_FireFart_'
  puts ' Sponsored by the RandomStorm Open Source Initiative'
  puts '_____________________________________________________'
  puts
end

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text)
  colorize(text, 31)
end

def green(text)
  colorize(text, 32)
end

def xml(file)
  Nokogiri::XML(File.open(file)) do |config|
    config.noblanks
  end
end

def redefine_constant(constant, value)
  Object.send(:remove_const, constant)
  Object.const_set(constant, value)
end

# Gets the string all elements in stringarray ends with
def get_equal_string_end(stringarray = [''])
  already_found = ''
  looping = true
  counter = -1
  # remove nils (# Issue #232)
  stringarray = stringarray.compact
  if stringarray.kind_of? Array and stringarray.length > 1
    base = stringarray.first
    while looping
      character = base[counter, 1]
      stringarray.each do |s|
        if s[counter, 1] != character
          looping = false
          break
        end
      end
      if looping == false or (counter * -1) > base.length
        break
      end
      already_found = "#{character if character}#{already_found}"
      counter -= 1
    end
  end
  already_found
end
