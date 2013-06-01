class RubyEnthusiast
  def name
    'Petr Chalupa'
  end

  def works_at
    'Red Hat'
  end

  def to_github
    :'@pitr-ch'
  end
end

author = RubyEnthusiast.new
RedHatters = [author]

[ author.name      ==  %w(Petr Chalupa)*' ',
  RubyEnthusiast   === author,
  author.to_github == :'@pitr-ch'
].all? or
    raise EOWorldError
