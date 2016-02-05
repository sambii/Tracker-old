namespace :handlebars do
  task :minimize do
    `handlebars . -r ./app/views -f app/assets/javascripts/templates.js -m`
  end

  task :precompile do
    `handlebars . -r ./app/views -f app/assets/javascripts/templates.js`
  end
end