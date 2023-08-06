#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

echo -e "\n~~~~~ Number Guessing Game ~~~~~\n"

MAIN_FUNC ()
{
  echo -e "Enter your username:"
  read USERNAME

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  if [[ -z $USER_ID ]]
  then
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."

    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  else
    BEST_GAME=$($PSQL "SELECT MIN(number_of_guess) FROM games WHERE user_id=$USER_ID AND finished='t'")
    GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID AND finished='t'")

    if [[ -z $BEST_GAME ]]
    then
      BEST_GAME=0
    fi

    if [[ -z $GAMES_PLAYED ]]
    then
      GAMES_PLAYED=0
    fi

    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  INSET_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, secret_number) VALUES($USER_ID, $SECRET_NUMBER)")
  GAME_ID=$($PSQL "SELECT game_id FROM games WHERE user_id=$USER_ID ORDER BY game_id DESC LIMIT 1")

  PLAY_FUNC "Guess the secret number between 1 and 1000:" $GAME_ID 0

}

PLAY_FUNC ()
{
  GAME_ID=$2
  COUNT=$3

  echo -e "\n$1"
  read USER_GUESS

  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    PLAY_FUNC "That is not an integer, guess again:" $GAME_ID $COUNT
  else
    COUNT=$(($COUNT + 1))
    if [[ $USER_GUESS -gt $SECRET_NUMBER ]]
    then

      PLAY_FUNC "It's lower than that, guess again:" $GAME_ID $COUNT

    elif [[ $USER_GUESS -lt $SECRET_NUMBER ]]
    then

      PLAY_FUNC "It's higher than that, guess again:" $GAME_ID $COUNT

    else

      SET_FINISH=$($PSQL "UPDATE games SET finished='t', number_of_guess=$COUNT WHERE game_id=$GAME_ID")
      echo -e "\nYou guessed it in $COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    fi
  fi
}

MAIN_FUNC
