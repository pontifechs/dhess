module dhess.Pieces;


enum Piece
{
  King = 0,
  Queen = 1,
  Bishop = 2,
  Knight = 3,
  Rook = 4,
  Pawn = 5
}

enum Color: int
{
  White = 0,
  Black = 1
}

Color not(Color c)()
{
  static if (c == Color.Black)
  {
    return Color.White;
  }
  else if (c == Color.White)
  {
    return Color.Black;
  }
}

Color not(Color c)
{
  if (c == Color.Black)
  {
    return Color.White;
  }
  else
  {
    return Color.Black;
  }
}

import std.typecons;

alias ColorPiece = Tuple!(Color, "color", Piece, "piece");
