require 'json'
request = {}
request[:profile_id] = 'e482fb88ff5142612d721dee7bdf9017'
request[:subdomain] = 'branch-name'
request[:repos] = { 'merb-recaptcha' => 'branch-name', 'mysageone_ca' => 'branch_name'}
request[:inputs] = { 'APP_FUGU_THEME' => 'value', 'REGISTER_DNS' => 'value'}
payload = {'payload' => request}
json = payload.to_json
File.open("request.json", "w") do |f|
  f.write(json)
end