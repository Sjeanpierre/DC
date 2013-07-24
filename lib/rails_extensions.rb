class Array
  def to_hashie
    map {|array| Hashie::Mash.new(array)}
  end
end