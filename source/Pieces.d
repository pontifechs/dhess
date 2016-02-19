module chess.Pieces;


enum Piece
{
  King,
  Queen,
  Bishop,
  Knight,
  Rook,
  Pawn
}

enum Color: int
{
  White = 0,
  Black = 1
}

Color not(Color c)()
{
  if (c == Color.Black)
  {
    return Color.White;
  }
  else if (c == Color.White)
  {
    return Color.Black;
  }
}

import std.typecons;

alias ColorPiece = Tuple!(Color, "color", Piece, "piece");
