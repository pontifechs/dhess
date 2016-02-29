module dhess.Move;

import dhess.Pieces;
import dhess.Position;

import std.typecons;

struct Move
{
  Piece piece;
  Square source;
  Square destination;

  Piece capture = Piece.None;
  Square captureSquare;

  Piece promotion = Piece.None;

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

    if (this.capture != rhs.capture)
    {
      return (this.capture > rhs.capture) ? 1 : -1;
    }

    if (this.captureSquare != rhs.captureSquare)
    {
      return (this.captureSquare > rhs.captureSquare) ? 1 : -1;
    }
    return (this.promotion < rhs.promotion) ? 1 : -1;
  }

  bool isCastling() const
  {
    if (this.piece != Piece.King)
    {
      return false;
    }
    if (!(this.source == Square.E1 || this.source == Square.E8))
    {
      return false;
    }
    return (this.source == Square.E1 && this.destination == Square.G1) ||
           (this.source == Square.E1 && this.destination == Square.C1) ||
           (this.source == Square.E8 && this.destination == Square.G8) ||
           (this.source == Square.E8 && this.destination == Square.C8);
  }

  bool isQuiet() const
  {
    return capture == Piece.None;
  }
}

// isCastling
unittest
{
  auto move = Move(Piece.King, Square.E1, Square.C1);
  assert(move.isCastling);

  auto notCastle = Move(Piece.Queen, Square.E1, Square.C1);
  assert(!notCastle.isCastling);

  auto almost = Move(Piece.King, Square.E1, Square.B1);
  assert(!almost.isCastling);
}

