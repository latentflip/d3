files = Dir.glob('./data/*.json')

f = 'users.json'

`echo "[" > #{f}`

`cat data/*.json >> #{f}`

`echo "]" >> #{f}`
