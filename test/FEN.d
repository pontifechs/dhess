import dhess.FEN;
import dhess.Pieces;
import dhess.Position;

import std.typecons;

// Move clocks;
unittest
{
  assert(START.drawClock == 0);
  assert(START.moveClock == 1);

  FEN longGame = "8/8/8/8/8/8/8/8 w KQkq - 49 999";
  assert(longGame.drawClock == 49);
  assert(longGame.moveClock == 999);
}

// enPassant
unittest
{
  FEN f3 = "8/8/8/8/8/8/8/8 w KQkq f3 0 1";
  auto f3enPassant = f3.enPassant;
  assert(!f3enPassant.isNull);
  assert(f3enPassant.get() == Square.F3);
}

// Castling
unittest
{
  FEN all = "8/8/8/8/8/8/8/8 w KQkq - 0 1";
  auto allCastling = all.castling;
  assert(allCastling[Color.White][Piece.King]);
  assert(allCastling[Color.White][Piece.Queen]);
  assert(allCastling[Color.Black][Piece.King]);
  assert(allCastling[Color.Black][Piece.Queen]);

  FEN noBlack = "8/8/8/8/8/8/8/8 w KQ - 0 1";
  auto noBlackCastling = noBlack.castling;
  assert(noBlackCastling[Color.White][Piece.King]);
  assert(noBlackCastling[Color.White][Piece.Queen]);
  assert(!noBlackCastling[Color.Black][Piece.King]);
  assert(!noBlackCastling[Color.Black][Piece.Queen]);
}

// Invalid chunk length
unittest
{
  FEN fen = "";
  assert(!fen.valid);
}

// Invalid active player
unittest
{
  FEN invalidChar = "8/8/8/8/8/8/8/8 x KQkq - 0 1";
  assert(!invalidChar.valid);
}

// valid positions
unittest
{
  assert("a1".validPosition);
  assert("b2".validPosition);
  assert("c3".validPosition);
  assert("d4".validPosition);
  assert("h8".validPosition);
  assert(!"i8".validPosition);
  assert(!"h9".validPosition);
}

// valid en passant
unittest
{
  FEN validEnPassant = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  assert(validEnPassant.valid);

  FEN invalidEnPassant1 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq x 0 1";
  assert(!invalidEnPassant1.valid);

  FEN invalidEnPassant2 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq x9 0 1";
  assert(!invalidEnPassant2.valid);
}

// invalid move/half-move
unittest
{
  FEN invalidHalfMove = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - n 1";
  assert(!invalidHalfMove.valid);

  FEN invalidMove = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 K";
  assert(!invalidMove.valid);
}

// valid
unittest
{
  assert(START.valid);
}

// parse board
unittest
{
  FEN fen = START;

  auto board = fen.parseBoard;

  auto whiteBack = [Nullable!ColorPiece(ColorPiece(Color.White, Piece.Rook)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Knight)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Bishop)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.King)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Queen)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Bishop)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Knight)),
                    Nullable!ColorPiece(ColorPiece(Color.White, Piece.Rook))];
  auto blackBack = [Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Rook)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Knight)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Bishop)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.King)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Queen)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Bishop)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Knight)),
                    Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Rook))];

  auto whitePawns = [Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn))];
  auto blackPawns = [Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn)),
                     Nullable!ColorPiece(ColorPiece(Color.Black, Piece.Pawn))];

  auto empty = [Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece()];

  check(board[0], whiteBack);
  check(board[1], whitePawns);
  check(board[2], empty);
  check(board[3], empty);
  check(board[4], empty);
  check(board[5], empty);
  check(board[6], blackPawns);
  check(board[7], blackBack);
}

unittest
{
   FEN fen = "8/8/8/8/8/8/PPPPPPPP/RNBQ4 w KQkq - 0 1";

  auto board = fen.parseBoard;

  auto back = [Nullable!ColorPiece(),
               Nullable!ColorPiece(),
               Nullable!ColorPiece(),
               Nullable!ColorPiece(),
               Nullable!ColorPiece(ColorPiece(Color.White, Piece.Queen)),
               Nullable!ColorPiece(ColorPiece(Color.White, Piece.Bishop)),
               Nullable!ColorPiece(ColorPiece(Color.White, Piece.Knight)),
               Nullable!ColorPiece(ColorPiece(Color.White, Piece.Rook))];
  auto pawns = [Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn)),
                Nullable!ColorPiece(ColorPiece(Color.White, Piece.Pawn))];
  auto empty = [Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece(),
                Nullable!ColorPiece()];


  check(board[0], back);
  check(board[1], pawns);
  check(board[2], empty);
  check(board[3], empty);
  check(board[4], empty);
  check(board[5], empty);
  check(board[6], empty);
  check(board[7], empty);
}

private void check(Nullable!ColorPiece[] left, Nullable!ColorPiece[] right)
{
  assert (left.length == right.length);
  for (int i = 0; i < left.length; ++i)
  {
    if (left[i].isNull)
    {
      assert(right[i].isNull, "is null");
      continue;
    }
    assert(left[i] == right[i], "equal");
  }
}
