import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris_game/piece.dart';
import 'package:tetris_game/pixel.dart';
import 'package:tetris_game/values.dart';

List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // current tetris pieces
  Piece currentPiece = Piece(type: Tetromino.L);

  //current score
  int currentScore = 0;

  // game over statues
  bool gameOver = false;

  @override
  void initState() {
    super.initState();

    // start game when app starts
    startGame();
  }

  // startGame
  void startGame() {
    currentPiece.initializePiece();

    //frame refresh rate
    Duration frameRate = const Duration(milliseconds: 500);
    gameLoop(frameRate);
  }

  // game loops
  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        //clear lines
        clearLines();

        //check landing
        checkLanding();

        //check if game is over
        if (gameOver == true) {
          timer.cancel();
          showGameOverDialog();
        }

        //move current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  //game over message
  void showGameOverDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Game Over'),
              content: Text('Your score is: $currentScore'),
              actions: [
                TextButton(
                    onPressed: () {
                      //reset the game
                      resetGame();
                      Navigator.pop(context);
                    },
                    child: const Text('Play Again'))
              ],
            ));
  }

  //reset game
  void resetGame() {
    //clear the game board
    gameBoard = List.generate(
        colLength,
        (i) => List.generate(
              rowLength,
              (j) => null,
            ));

    //new game
    gameOver = false;
    currentScore = 0;

    //crate new piece
    createNewPiece();

    //start game again
    startGame();
  }

  // check for collision in a future position
  // return true -> there is a collision
  // return false -> there is no collision
  bool checkCollision(Direction direction) {
    // loop through each position of the current position
    for (int i = 0; i < currentPiece.position.length; i++) {
      // calculate the row and column of the current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      //check if the piece is out of bounds (either too low or too far to the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }
    }
    // if no collision are detected , return false
    return false;
  }

  // checkLanding
  void checkLanding() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      // mark position as occupied on the game board
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      // once landed, create the next piece
      createNewPiece();
    }
  }

  // createNewPiece
  void createNewPiece() {
    // create a random object to generate random tetromino type
    Random rand = Random();

    // create a new piece with random type
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if (isGameOver()) {
      gameOver = true;
    }
  }

  //move left
  void moveLeft() {
    // make sure the move is valid before moving here
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  // move right
  void moveRight() {
    // make sure the move is valid before moving here
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  // rotate piece
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  // clear lines
  void clearLines() {
    // step 1: Loop through each row of the game board from bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      //step 2: Initialize a variable to track if the row is full
      bool rowIsFull = true;

      // step 3: Check if the row if full (all columns in the row are filled with pieces)
      for (int col = 0; col <= rowLength; col++) {
        //if there's an empty column, set rowIsFull to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // step 4: if the row is full, clear the row and shift rows down
      if (rowIsFull) {
        //step 5: move all rows above the cleared row down by one position
        for (int r = row; r > 0; r--) {
          //copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        //step 6: set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        //step 7: Increase the score!
        currentScore++;
      }
    }
  }

  //game over method
  bool isGameOver() {
    //check if any columns in the top row are filled
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }

    //if the top row is empty, the game is over
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
                itemCount: rowLength * colLength,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowLength),
                itemBuilder: (context, index) {
                  //get row and col of each piece
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;

                  //current piece
                  if (currentPiece.position.contains(index)) {
                    return Pixel(
                      color: currentPiece.color,
                    );
                  }
                  //landed pieces
                  else if (gameBoard[row][col] != null) {
                    final Tetromino? tetrominoType = gameBoard[row][col];
                    return Pixel(
                      color: tetrominoColors[tetrominoType],
                    );
                  }
                  //blank piece
                  else {
                    return Pixel(
                      color: Colors.grey[900],
                    );
                  }
                }),
          ),
          // Score
          Text(
            'Score: $currentScore',
            style: const TextStyle(color: Colors.white),
          ),

          // Game Controls
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, top: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //left
                IconButton(
                    onPressed: moveLeft,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_ios)),
                //rotate
                IconButton(
                    onPressed: rotatePiece,
                    color: Colors.white,
                    icon: const Icon(Icons.rotate_right)),
                //right
                IconButton(
                    onPressed: moveRight,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_forward_ios)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
