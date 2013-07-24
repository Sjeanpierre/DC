details_hash = {:tag_info => [{:title_1 => {:key1 => 1, :key2 => 2}},{:title_2 => {:key1 => 1, :key2 => 2}}]}
details_hash[:tag_info].map! {|repo| repo[repo.keys[0]]}
details_hash[:tag_info].each do |detail|
  detail.each do |key,value|
    p
  end
end
p