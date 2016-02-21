module dhess.Move;

import dhess.Pieces;
import dhess.Position;

import std.typecons;


struct Move
{
  Piece piece;
  Square source;
  Square destination;

  Piece promotion = Piece.Pawn;

  int opCmp(ref const Move rhs) const
  {
    if (this.piece != rhs.piece)
    {
      return (this.piece < rhs.piece) ? 1 : -1;
    }

    if (this.source != rhs.source)
    {
      return (this.source > rhs.source) ? 1 : -1;
    }

    if (this.destination != rhs.destination)
    {
      return (this.destination > rhs.destination) ? 1 : -1;
    }

    return (this.promotion < rhs.promotion) ? 1 : -1;
  }
}


