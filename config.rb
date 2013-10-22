###
# Site settings
###

# Look in data/site.yml for general site configuration


Time.zone = data.site.timezone || "UTC"

# Make pretty URLs
activate :directory_indexes

# Automatic image dimensions on image_tag helper
activate :automatic_image_sizes

# Syntax highlighting
activate :syntax

# Bootstrap navbar
activate :bootstrap_navbar

# Make URLs relative
set :relative_links, true

# Set HAML to render HTML5 by default (when unspecified)
# It's important HAML outputs "ugly" HTML to not mess with code blocks
set :haml, :format => :html5, :ugly => true

# Set Markdown features for RedCarpet
# (So our version of Markdown resembles GitHub's)
set :markdown,
  :tables => true,
  :autolink => true,
  :gh_blockcode => true,
  :fenced_code_blocks => true,
  :smartypants => true

set :markdown_engine, :redcarpet

set :asciidoctor,
  :toc => true,
  :numbered => true


# Set directories
set :css_dir, 'stylesheets'
set :fonts_dir, 'stylesheets/fonts'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :partials_dir, 'layouts'


###
# Blog settings
###

activate :blog do |blog|
  blog.prefix = "blog/"
  blog.layout = "blog_layout"
  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"
  blog.default_extension = ".md"

  blog.sources = ":year-:month-:day-:title.html"
  blog.permalink = ":year/:month/:day/:title.html"
  blog.year_link = ":year.html"
  blog.month_link = ":year/:month.html"
  blog.day_link = ":year/:month/:day.html"


  #blog.taglink = "tags/:tag.html"

  #blog.summary_separator = /(READMORE)/
  #blog.summary_length = 99999

  blog.paginate = true
  blog.per_page = 10
  blog.page_link = "page/:num"
end

#activate :authors
#activate :drafts

# Enable blog layout for all blog pages
with_layout :blog_layout do
  page "/blog.html"
  page "/blog/*"
end


###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end


###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Don't have a layout for XML
page "/feed.xml", :layout => false
page "/sitemap.xml", :layout => false

# Docs all have the docs layout
with_layout :docs do
  page "/documentation/*"
  page "/documentation*"
end

# Proxy pages (http://middlemanapp.com/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }


###
# Helpers
###

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end
helpers do
  def normalize_url(dirty_URL)
    r = url_for Middleman::Util.normalize_path(dirty_URL)
    r.sub(/\/$/, '')
  end

  # FIXME: This is a WIP; it's not working though...
  def pretty_date(sometime)
    #sometime = ActiveSupport::TimeZone[zone].parse(sometime) unless sometime.is_a?(Date)
    sometime = Date.strptime(sometime, "%Y-%m-%d") if sometime.is_a?(String)
=begin
    if date.is_a?(String)
      date = Date.parse(date)
    end

    result = date.strftime("%B %d")
    result << date.strftime(", %Y") if date.year > Time.now.year
=end

    #return sometime.to_formatted_s(:short)
    return sometime#.strftime("%d %B")
  end

  # Use the title from frontmatter metadata,
  # or peek into the page to find the H1,
  # or fallback to a filename-based-title
  def discover_title(page = current_page)
    page.data.title || page.render({layout: false}).match(/<h1>(.*?)<\/h1>/) do |m|
      m ? m[1] : page.url.split(/\//).last.titleize
    end
  end

end


###
# Development-only configuration
###
#
configure :development do
  activate :livereload
  #config.sass_options = {:debug_info => true}
  #config.sass_options = {:line_comments => true}
  compass_config do |config|
    config.output_style = :expanded
    config.sass_options = {:debug_info => true, :line_comments => true}
  end
end

# Build-specific configuration
configure :build do
  ## Ignore Gimp source files
  ignore 'images/*.xcf*'

  # Don't export source JS
  ignore 'javascripts/vendor/*'
  ignore 'javascripts/lib/*'

  # Don't export source CSS
  ignore 'stylesheets/vendor/*'
  ignore 'stylesheets/lib/*'

  # Minify JavaScript and CSS on build
  activate :minify_javascript
  activate :minify_css
  activate :gzip

  # Force a browser reload for new content by using
  # asset_hash or cache buster (but not both)
  activate :cache_buster
  # activate :asset_hash

  # Use relative URLs for all assets
  activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"

  # Favicon PNG should be 144×144 and in source/images/favicon_base.png
  activate :favicon_maker,
    favicon_maker_input_dir: "source/images",
    favicon_maker_output_dir: "build/images",
    favicon_maker_base_image: "favicon_base.png"
end


###
# Deployment
##

if data.site.openshift
  os_token, os_host = data.site.openshift.match(/([0-9a-f]+)@([^\/]+)/).captures

  deploy_config = {
    method: :rsync,
    user: os_token,
    host: os_host,
    path: "/var/lib/openshift/#{os_token}/app-root/repo",
    clean: true, # remove orphaned files on remote host
    build_before: true # default false
  }

elsif data.site.rsync
  rsync = URI.parse(data.site.rsync)

  deploy_config = {
    method: :rsync,
    user: rsync.user || ENV[:USER],
    host: rsync.host,
    path: rsync.path,
    port: rsync.port || 22,
    clean: true, # remove orphaned files on remote host
    build_before: true # default false
  }

else
  # For OpenShift,
  #
  # 1) use the barebones httpd cartridge from:
  #    http://cartreflect-claytondev.rhcloud.com/reflect?github=stefanozanella/openshift-cartridge-httpd
  #    (Add as URL at the bottom of the create from cartridge page)
  #
  # 2) Copy your new site's git repo URL and use it for 'production':
  #    git remote add production OPENSHIFT_GIT_REMOTE_HERE
  #
  # 3) Now, you can easily deploy to your new OpenShift site!
  #    bundle exec middleman deploy

  deploy_config = {
    method: :git,
    remote: "production",
    branch: "master",
    build_before: true # default false
  }
end

activate :deploy do |deploy|
  deploy_config.each {|key, val| deploy[key] = val }
end