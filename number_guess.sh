#!/bin/bash

# Set up the database query preface variable.
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt the user to enter their username.
echo "Enter your username:"

# Enter the user's submitted username into a variable.
read USERNAME

# Query the database for the user's username.
USERNAME_IN_DATABASE=$($PSQL "SELECT username FROM users WHERE username='$USERNAME'")

# If the variable is empty, that means the user is new to the game, since they aren't in the database. If the variable isn't empty, then the user has previously played before.
if [[ -z $USERNAME_IN_DATABASE ]]
then
  # Since the user is new, give them a 'welcome' message.
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # Since the user is returning, query the database for information about their previous games, and give them a 'welcome back' message using that information.
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  LOWEST_GUESS_COUNT=$($PSQL "SELECT lowest_guess_count FROM users WHERE username='$USERNAME'")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $LOWEST_GUESS_COUNT guesses."
fi

# Generate a random number between 1 and 1000 (the 'secret number') that the user will have to guess.
SECRET_NUMBER=$(( 1 + RANDOM % 1000 ))

# Set up the variable that will be used to track how many guesses the user has made in the current game.
CURRENT_GUESS_COUNT=0

# Prompt the user to guess the secret number.
echo "Guess the secret number between 1 and 1000:"

# Enter a loop and will keep going until the user guesses the secret number.
while [[ $NUMBER_GUESSED != $SECRET_NUMBER || $CURRENT_GUESS_COUNT == 0 ]]
do
  # Enter the user's submitted number into a variable.
  read NUMBER_GUESSED

  # Add the guess the user just made to their total amount of guesses so far.
  (( CURRENT_GUESS_COUNT++ ))

  # If the user doesn't submit an integer as their guess, notify them about their mistake.
  if [[ ! $NUMBER_GUESSED =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  # If the secret number is higher than the user's guess, tell them as such.
  elif [[ $SECRET_NUMBER -gt $NUMBER_GUESSED ]]
  then
    echo "It's higher than that, guess again:"
  # If the secret number is lower than the user's guess, tell them as such.
  elif [[ $SECRET_NUMBER -lt $NUMBER_GUESSED ]]
  then
    echo "It's lower than that, guess again:"
  fi
done

# The user has exited the loop, which means they guessed correctly. Give them a congratulation message which includes information about the game session they just played.
echo "You guessed it in $CURRENT_GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

# Check once again if the user is new or returning, to determine how to insert their game session information into the database.
if [[ -z $USERNAME_IN_DATABASE ]]
then
  # Since the user is new, insert a new row into the database's 'users' table containing the user's information.
  INSERT_USER_INTO_DATABASE=$($PSQL "INSERT INTO users(username, games_played, lowest_guess_count) VALUES ('$USERNAME', 1, $CURRENT_GUESS_COUNT)")
else
  # Since the user is returning, add the game session they just played to their total number of game sessions.
  (( GAMES_PLAYED++ ))
  # Use that incremented game session count to update the user's corresponding information in the database.
  UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'")

  # Check if the user beat their best score in the game session they just played.
  if [[ $CURRENT_GUESS_COUNT -lt $LOWEST_GUESS_COUNT ]]
  then
    # If the user did beat their best score, update their best score in the database.
    UPDATE_LOWEST_GUESS_COUNT=$($PSQL "UPDATE users SET lowest_guess_count=$CURRENT_GUESS_COUNT WHERE username='$USERNAME'")
  fi
fi