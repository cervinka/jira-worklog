require 'commander/import'

program :name, 'jira-worklog'
program :version, '0.0.1'
program :description, 'Add worklog to JIRA using REST API'
# program :help_formatter, :compact

global_option '-u', '--user USERNAME', 'JIRA login username'
global_option '-p', '--password PASSWORD', 'JIRA login password'
global_option '-b', '--url-base BASE_URL', 'JIRA base URL. ie: https://jira.example.com/rest/api/2/'

command :issues do |c|
  c.syntax = 'jira-worklog issues [options]'
  c.summary = 'List available issues'
  # c.description = ''
  c.example 'list issues', 'jira-worklog issues -u USERNAME -p PASSWORD -b BASE_URL'
  c.action do |_args, options|
    url_base, user, password = get_credentials(options)
    api = APIClient.new(url_base,user, password)
    # api = Jira::Worklog::APIClient.new(url_base,user, password)
    api.issues.each do |issue|
      puts "#{issue[:key]} (issue_id #{issue[:id]}) - #{issue[:summary]}"
    end
  end
end

command :add do |c|
  c.syntax = 'jira-worklog add [options]'
  c.summary = 'Add new worklog entries to JIRA'
  c.description= <<DESCRIPTION
- input file must contain 4 columns and each column is required  (additional rows are ignored)
  - 1st column: issue key or id
  - 2nd column: date (start time is set to 7am automatically)
  - 3rd column: duration in hours
  - 4th column: comment
DESCRIPTION
  c.example 'description', 'jira-worklog add -u USER -p PASSWORD -b BASE_URL --xlsx FILE.XLSX'
  c.option '--xlsx FILE', 'Add new entries to JIRA workog from xlsx file'
  c.action do |_args, options|
    raise '--xlsx is mandatory parameter' unless options.xlsx
    url_base, user, password = get_credentials(options)
    api = APIClient.new(url_base, user, password)
    worklogs = load_from_xlsx(options.xlsx)
    worklog_ids = []

    worklogs.each do |worklog|
      worklog_id = api.add_worklog(worklog)
      worklog_ids << worklog_id
      puts "#{formatted_duration(worklog[:duration])} - (id: #{worklog_id}) #{worklog[:date]} #{worklog[:issue]} #{worklog[:comment]}"
    end
    puts '-' * 60
    puts "#{formatted_duration(worklogs.inject(0) { |sum, worklog| sum + worklog[:duration] })} inserted"
    puts "New ids: #{worklog_ids.join(',')}"
  end
end

command :delete do |c|
  c.syntax = 'jira-worklog delete ISSUE WORKLOG_IDS'
  c.summary = 'Delete worklog entries by ids (comma separated)'
  c.example 'delete worklogs', 'jira-worklog delete -u USER -p PASSWORD -b BASE_URL WORKLOG1_ID,WORKLOG2_ID,...'
  c.action do |args, options|
    issue = args[0].to_s
    raise 'please specify issue key or id' if issue.nil?
    ids = args[1].to_s.split(',')
    raise 'please specify worklog ids (comma separated)' if ids.empty?
    url_base, user, password = get_credentials(options)
    api = APIClient.new(url_base, user, password)
    ids.each do |worklog_id|
      puts "Deleting worklog ##{worklog_id}"
      api.delete_worklog(issue, worklog_id)
    end

  end
end

command :list do |c|
  c.syntax = 'jira-worklog list [options]'
  c.summary = 'List worklog entries for given issue'
  c.description = ''
  c.example 'list worklogs for given issue', 'jira-worklog list -u USER -p PASSWORD -b BASE_URL --issue ISSUE_ID_OR_KEY'
  c.option '--issue ISSUE', 'JIRA Issue Key or Id (use "issues" command to list available issues)'
  c.action do |_args, options|
    raise '--issue is mandatory parameter' unless options.issue
    url_base, user, password = get_credentials(options)
    api = APIClient.new(url_base, user, password)
    worklogs = api.worklogs(options.issue)
    worklog_ids = []
    worklogs.each do |worklog|
      puts "#{formatted_duration(worklog[:duration])} - (id: #{worklog[:id]}) #{worklog[:date]} #{worklog[:comment]}"
      worklog_ids << worklog[:id]
    end
    puts '-' * 60
    puts "#{formatted_duration(worklogs.inject(0) { |sum, worklog| sum + worklog[:duration] })} total"
    puts "Worklog ids: #{worklog_ids.join(',')}"
  end
end

def load_from_xlsx(filename)
  doc = SimpleXlsxReader.open(filename)
  doc.sheets # => [<#SXR::Sheet>, ...]
  sheet = doc.sheets.first
  puts "Loading from sheet: #{sheet.name}"
  worklogs = []
  sheet.rows.each.with_index do |row, idx|
    issue, date, duration, comment = row[0], row[1], row[2], row[3]
    duration = Float(duration) rescue 0
    if issue && !issue.nil? && !issue.empty? && date.is_a?(Date) && duration > 0 && comment && !comment.nil? && !comment.empty?
      worklogs << ({issue: issue, date: date, duration: duration * 3600, comment: comment})
    else
      puts "Skipping row ##{idx + 1}: #{row.inspect}"
    end
  end
  worklogs
end

def formatted_duration(total_seconds)
  hours = total_seconds / (60 * 60)
  minutes = (total_seconds / 60) % 60
  seconds = total_seconds % 60
  '%2d:%02d:%02d' % [hours, minutes, seconds]
end

def get_credentials(options)
  user = options.user || ask('JIRA user: ')
  password = options.password || ask('JIRA password: ') { |q| q.echo = '*' }
  url_base = options.url_base
  raise('--url_base is mandatory option') if url_base.nil? || url_base.empty?
  [url_base, user, password]
end
