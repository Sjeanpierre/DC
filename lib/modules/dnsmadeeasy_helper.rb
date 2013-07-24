module DnsmadeeasyHelper
  require 'hashie'

  class Dns
    def self.new
      @dns_client = DnsMadeEasy::Api.new(DNS_CONFIG['api_key'],DNS_CONFIG['secret_key'])
      self
    end

    def self.domain(domain_name)
      Domain.new(domain_name)
    end

    def self.domains
      domains = @dns_client.list_domains
      domains.map! { |domain| Domain.new(domain) }
      domains
    end

    def self.list_domains
      @dns_client.list_domains
    end

    def self.records(domain)
      @dns_client.list_records(domain).to_hashie
    end

    def self.create_record(domain,record)
      @dns_client.create_record!(domain,record)
    end

    def self.update_record(domain,record_id,update_hash)
      @dns_client.update_record!(domain,record_id,update_hash)
    end

    def self.delete_record(domain,record_id)
      @dns_client.delete_record!(domain,record_id)
    end

  end

  class Domain
    def self.new(domain)
      @domain = domain
      @client = Dns.new
      self
    end

    def self.records
      @client.records(@domain)
    end

    def self.record_exists?(record)
      records = self.records
      existing_records = records.map {|subdomain| subdomain.name}
      existing_records.include?(record)
    end

    def self.create_subdomain(sub_domain)
      raise("cannot create sub-domain #{sub_domain} because it already exist for domain #{@domain}") if self.record_exists?(sub_domain)
      subdomain_record = {:name => sub_domain, :type => 'A', :data => '0.0.0.0', :ttl => 5}
      @client.create_record(@domain,subdomain_record)
    end

    def self.delete_subdomain(sub_domain_id)
      @client.delete_record(@domain,sub_domain_id)
    end

    def self.update_subdomain(sub_domain,record_id,ip_info)
      raise("sub-domain #{sub_domain} does not exist for domain #{@domain}") unless self.record_exists?(sub_domain)
      update_hash = {:data => ip_info}
      @client.update_record(@domain,record_id,update_hash)
    end

  end
end
