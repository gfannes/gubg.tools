puts("Welcome to SuPR")

here = File.dirname(__FILE__)
$LOAD_PATH << File.dirname(here)

require('supr/app')

app = Supr::App.new()
app.()

puts("Everything went OK")