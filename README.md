# Hubot Snippets

Implements a method to perform Google Snippets task tracking


## Installation

Add **hubot-snippets** to your `package.json` file:

```json
"dependencies": {
  ...
  "hubot-snippets": "latest"
}
```

Add **hubot-snippets** to your `external-scripts.json`:

```json
["hubot-snippets"]
```

Run `npm install hubot-snippets`


## Configuration


## Commands
    #standup <message>                              # Record a standup message for the day
    #sitdown <message>                              # Record a sitdown message for the day
    #sitdown (<YYYY-MM-DD> || yesterday) <message>  # Record a sitdown message for a give date
