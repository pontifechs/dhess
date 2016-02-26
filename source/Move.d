module dhess.Move;

import dhess.Pieces;
import dhess.Position;

import std.typecons;

// TODO:: Lots of things should probably be in here rather than calculated elsewhere.
// Things like if it's a castle, capture, Quiet, to optimize the inCheck away, etc.
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

  bool isCastling() const
  {
    if (this.piece == Piece.King)
    {
      return false;
    }
    if (this.source != Square.E1 && this.source != Square.E8)
    {
      return false;
    }
    return (this.source == Square.E1 && this.destination == Square.G1) ||
           (this.source == Square.E1 && this.destination == Square.C1) ||
           (this.source == Square.E8 && this.destination == Square.G8) ||
           (this.source == Square.E8 && this.destination == Square.C8);
  }
}


