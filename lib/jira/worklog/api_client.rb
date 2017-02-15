class APIClient
  attr_reader :user, :password, :url_base

  def initialize(url_base, user, password)
    @user = user
    @password = password
    @url_base = url_base
  end


  def issues
    data = request("search?jql=assignee=#{user}")
    data['issues'].map { |issue| {key: issue['key'], id: issue['id'], summary: issue['fields']['summary']} }
  end

  def delete_worklog(issue, worklog_id)
    delete_request("issue/#{issue}/worklog/#{worklog_id}")
  end

  def add_worklog(worklog)
    req = {
        comment: worklog[:comment],
        started: worklog[:date].strftime('%Y-%m-%d') + 'T07:00:00.000+0100',
        timeSpentSeconds: worklog[:duration]
    }
    data = post_request("issue/#{worklog[:issue]}/worklog", req.to_json)
    # puts "added: #{worklog.inspect}"
    data['id']
  end


  def worklogs(issue)
    data = request("issue/#{issue}/worklog")
    # pp data
    data['worklogs'].map { |worklog|
      {
          duration: worklog['timeSpentSeconds'],
          comment: worklog['comment'],
          issue_id: worklog['issueId'],
          id: worklog['id'],
          date: Date.strptime(worklog['started'][0..9], '%Y-%m-%d')
      }
    }
  end

  private
  def request(path)
    url = url_base + path
    resp = RestClient::Request.execute method: :get, url: url, user: user, password: password, :verify_ssl => false
    JSON.parse resp.body
  end

  def delete_request(path)
    url = url_base + path
    RestClient::Request.execute method: :delete, url: url, user: user, password: password, :verify_ssl => false
  end

  def post_request(path, payload)
    url = url_base + path
    resp = RestClient::Request.execute method: :post, url: url, user: user, password: password, :verify_ssl => false, payload: payload, headers: {'Content-Type' => 'application/json; charset=utf-8'}
    JSON.parse resp.body
  end

end
