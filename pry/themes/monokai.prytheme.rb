t = PryTheme.create :name => 'monokai' do
  author :name => 'Kyrylo Silin', :email => 'kyrylosilin@gmail.com'
  description "Based on Wimer Hazenberg's theme"

  define_theme do
    class_ 'sky01'
    class_variable 'white'
    comment 'pale_mauve01'
    constant 'sky01'
    error 'crimson', [:italic]
    float 'amethyst01'
    global_variable 'white'
    inline_delimiter 'white'
    instance_variable 'white'
    integer 'amethyst01'
    keyword 'crimson'
    method 'lime01'
    predefined_constant 'sky01'
    symbol 'amethyst01'

    regexp do
      self_ 'flax'
      char 'white'
      content 'flax'
      delimiter 'flax'
      modifier 'flax'
      escape 'white'
    end

    shell do
      self_ 'flax'
      char 'white'
      content 'flax'
      delimiter 'flax'
      escape 'white'
    end

    string do
      self_ 'flax'
      char 'white'
      content 'flax'
      delimiter 'flax'
      escape 'white'
    end
  end
end

PryTheme::ThemeList.add_theme(t)
