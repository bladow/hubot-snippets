# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
    #
    #   Provides a helpful reminder for unmatch standups
    #
    standing = (msg,stillStanding)->
        response = "BTW, you're still standing on " # Beginning of our canned response
        for stillStandingDate in stillStanding # Loop through all the standup dates
            response = response + stillStandingDate + ', ' # Add the date to the response string
        response = response + 'you must be tired.' # Closer of the response, minimum snark included
        msg.send response # Send the response to the user
        msg.send 'You can take the load off by submitting a "#sitdown (<date>) <message>' # Provide a polite help response to encourage some sit downs
    #
    # Listen for all messages starting with #standup
    #
    robot.hear /#standup (.*)/i, (msg) ->
        standupMsg = msg.match[1] # Extract the standup message, which is the first capture from the regex
        # Test this
        user = robot.brain.userForName msg.message.user.name # Get a pointer to the user record for the user that sent the message
        standDate = new Date() # Create a date object for "now"
        stood = false # Flag the new standup
        # Check to see if we've already stood up
        user.standups = user.standups or [] # Instantiate the standups array for the user. If the has existing standup records use those, otherwise create a new empty array
        stillStanding = [] # Instantiate an empty array to track unmatched standups
        for standup,i in user.standups # Loop though the standups to find the matching standup
            if(standDate.getDate() == standup.stamp.getDate() && standDate.getMonth() == standup.stamp.getMonth() && standDate.getFullYear() == standup.stamp.getFullYear())
                stood = true # Set the flag to show that the user has already stood up today
            if standup.sit is "" # While we're looping, check to see if there are any empty sitdown messages. Make a pretty date from the emptys
                month = (standup.stamp.getMonth() + 1) # Get the month (indexe at zero, so add one to make the user less confused)
                if month < 10 # Check for at least two digits
                    month = '0' + month # Zero pad the month
                day = standup.stamp.getDate() # Get the day
                if day < 10 # Check for at least two digits
                    day = '0' + day # Zero pad the day
                stillStanding.push(standup.stamp.getFullYear() + '-' + month + '-' + day) # Push the date of the missing sitdown to the array
        if stood is true # We've already done a standup today msg.send "Thanks #{msg.message.user.name}, but it appears like you've already stood up today." # Politely thank the user for having already submitted a standup if stillStanding.length > 0 # Check to see if we have any unanswered standups
                standing(msg,stillStanding) # Let the user know about it
        else # This is a brand new standup
            record = { stand:standupMsg, stamp:standDate, sit:"" } # Create a new standup object 
            user.standups.push(record) # Push this new record into the users standup collection
            user.workingon = standupMsg # Set the "workingon" field so that the user can easily be queried through the workingon.coffee module
            robot.brain.save # Save to the persistant store
            msg.send "Thanks #{msg.message.user.name} for standing up today." # Politely thank the user for submitting a standup
            if stillStanding.length > 0 # Check to see if we have any unanswered standups
                standing(msg,stillStanding) # Let the user know about it
    #
    # Listen for all message starting with #sitdown
    #
    robot.hear /#sitdown (.*)/i, (msg) ->
        sitMsg = msg.match[1]
        sitMatch = /\((.*)\) (.*)/.exec(sitMsg) # Check to see if the message is in the format "(<date) <message>, if this check fails the .exec will return null
        if sitMatch # Does this match a date formated message
            sitdown = sitMatch[2] # Extract out the sitdown message which is the second capture group from the regex
            if /yesterday/i.test(sitMatch[1]) # Check to see if the user is submitting a sitdown for "yesterday"
                currentDate = `new Date()` # Get today's date - need to do this in pure javascript to fix a type mismatch
                `currentDate.setDate(currentDate.getDate() - 1)` # Calculate the timestamp for "yesterday" - need to do this in pure javascript to fix a type mismatch
                sitDate = `new Date(currentDate)` # Set the date to "yesterday" - need to do this in pure javascript to fix a type mismatch
            else
                setDay = '\'' + sitMatch[1] + '\'' # Turn the submitted date into something we can pass to the Date() function
                sitDate = new Date(setDay) # Get the date object for the submitted date
        else # This is just a sitdown message for today, which is nice
            sitdown = sitMsg # Set the message
            sitDate = new Date();
        user = robot.brain.userForName msg.message.user.name # Get a pointer to the user record fo this user
        for standup,i in user.standups # Loop through the standups to find the sitdown match
            if standup.sit is "" # Check to see if the sitdown is empty
                if(sitDate.getDate() == standup.stamp.getDate() && sitDate.getMonth() == standup.stamp.getMonth() && sitDate.getFullYear() == standup.stamp.getFullYear()) # Does this date match the standup record's "stamp"
                    user.standups[i].sit = sitdown # Set the sitdown message
        robot.brain.save # Save to the persistant store
        msg.send "Ahhhhhh... That feels good. Thanks #{msg.message.user.name} for sitting down. Have a good day." # Politely thank the user for submitting a sitdown
    #
    # Set up a REST interface for standups
    #
    robot.router.get "/hubot/standups", (req,res) -> # New HTTP Listener on /hubot/standups
        data = [] # Initialize an empty array
        users = robot.brain.users() # Get a pointer to the users directory
        for key,user of users # Iterate through the users
            if user.standups # Check if the user has a standup
                stands = []
                for standup in user.standups # Loop through the standups
                    stands.push(standup) # Push the standup into the array
                data.push({username:user.name,standups:stands}) # Push the user standup object into the array
        res.end JSON.stringify(data) # Respond with the JSON object
    #
    # Set up a REST interface for standup per user
    #
    robot.router.get "/hubot/standups/user/:name", (req,res)-> # New HTTP listener on /hubot/standups/user/:name to pull standups for a particular user
        user = robot.brain.userForName req.params.name # Get a pointer to the user's data
        res.end JSON.stringify(user.standups) # Respond with the JSON object
    #
    # Set up a REST interface to enumerate the users of the standups
    #
    robot.router.get "/hubot/standups/users", (req,res)-> # New HTTP listener on /hubot/standups/users to pull standups for a particular user
        data = [] # Initialize an empty array
        users = robot.brain.users() # Get a pointer to the users
        for key, user of users # Iterate through the users
            if user.standups # Check if they have a standup
                data.push({username:user.name,id:user.id})
        res.end JSON.stringify(data) # Respond with the JSON object
    #
    # Set up a REST interface to return user count
    #
    robot.router.get "/hubot/standups/users/count", (req,res)-> # New HTTP listener on /hubot/standups/users to pull standups for a particular user
        numUsers = 0 # Initialize the user count
        users = robot.brain.users() # Get a pointer to the users
        for key, user of users # Iterate through the users
            if user.standups # Check if they have a standup
                numUsers++ # Increment the number of users
        res.end JSON.stringify({count:numUsers}) # Respond with the JSON object
