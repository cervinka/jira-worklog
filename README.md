# Jira::Worklog



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jira-worklog'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jira-worklog

## Usage

You can use JIRA API Client programatically (see `lib/jira/worklog/api_client.rb`) or as CLI utility `jira-worklog`



### CLI - List issues 

In order to add some worklog from excel, you need to know available issues (key or id). This command helps you to get list of issues:
 
```bash
jira-worklog issues -u MY_USERNAME -p MY_PASSWORD -b https://jira.example.com/rest/api/2/
```

### CLI - List worklogs for issue
 
```bash
jira-worklog list -u MY_USERNAME -p MY_PASSWORD -b https://jira.example.com/rest/api/2/ --issue ISUE_ID_OR_KEY 
```
 
### CLI - Add worklogs from xlsx file

File must be in excel xlsx form and must contain 4 colums (ussue_id_or_key, date, duration_in_hours, comment). For example file se `exmple.xlsx`.
 
```bash
jira-worklog add -u MY_USERNAME -p MY_PASSWORD -b https://jira.example.com/rest/api/2/ --xlsx FILE.XLSX
```
 
### CLI - delete worklogs

```bash
jira-worklog delete -u MY_USERNAME -p MY_PASSWORD -b https://jira.example.com/rest/api/2/ WORKLOG_ID1,WORKLOG_ID2,...
```
 

### Ruby API Client

```ruby
api = Jira::Worklog::APIClient.new(base_url, user, password)
api.issues()                    # list issues for logged user
api.worklogs(issue_id_or_key)   # fetch stored worklogs for given issue
api.add_worklog(worklog_data)   # add worklog - worklog_data is a Hash:
                                # {issue: 'ISSSUE_ID_OR_KEY', started: Date, duration: in_seconds, comment: 'comment'} 
api.delete_worklog(issue_id_or_key, worklog_id)                              

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jira-worklog.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

