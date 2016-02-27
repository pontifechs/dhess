module dhess.FEN;

import std.array;
import std.typecons;

import dhess.Pieces;
import dhess.Position;

alias FEN = string;

enum START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

private bool boardChunk(string boardChunk)
{
  import std.array;
  import std.conv;
  import std.ascii;

  auto rows = boardChunk.split("/");
  // Must have 8 rows of the board
  if (rows.length != 8)
  {
    return false;
  }

  // Each row must contain only valid pieces, and 8 total pieces
  foreach (row; rows)
  {
    int total = 0;
    foreach (c; row)
    {
      if (c.isDigit)
      {
        total += c.to!string.to!int;
        continue;
      }

      switch (c)
      {
      case 'k':
      case 'K':
      case 'q':
      case 'Q':
      case 'b':
      case 'B':
      case 'n':
      case 'N':
      case 'r':
      case 'R':
      case 'p':
      case 'P':
        total++;
        continue;
      default:
        return false;
      }
    }
    if (total != 8)
    {
      return false;
    }
  }
  return true;
}

private bool castlingChunk(string castlingChunk)
{
  if (castlingChunk.length > 4)
  {
    return false;
  }

  if (castlingChunk == "-")
  {
    return true;
  }

  bool seenK = false;
  bool seenk = false;
  bool seenQ = false;
  bool seenq = false;

  foreach (c; castlingChunk)
  {
    switch (c)
    {
    case 'K':
      if (seenK)
      {
        return false;
      }
      seenK = true;
      break;
    case 'k':
      if (seenk)
      {
        return false;
      }
      seenk = true;
      break;
    case 'Q':
      if (seenQ)
      {
        return false;
      }
      seenQ = true;
      break;
    case 'q':
      if (seenq)
      {
        return false;
      }
      seenq = true;
      break;
    default:
      return false;
    }
  }
  return true;
}

bool validPosition(string pos)
{
  if (pos.length != 2)
  {
    return false;
  }

  switch(pos[0])
  {
  case 'a':
  case 'b':
  case 'c':
  case 'd':
  case 'e':
  case 'f':
  case 'g':
  case 'h':
    break;
  default:
    return false;
  }

  switch(pos[1])
  {
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
    break;
  default:
    return false;
  }

  return true;
}


bool valid(FEN fen)
{
  import std.array;
  import std.string;

  import std.stdio;

  auto chunks = fen.split;
  if (chunks.length != 6)
  {
    return false;
  }

  // Validate board
  if (!chunks[0].boardChunk)
  {
    return false;
  }

  // The second chunk only contains whose turn it is
  switch (chunks[1])
  {
  case "w":
  case "b":
    break;
  default:
    return false;
  }

  // Castling availability
  if (!chunks[2].castlingChunk)
  {
    return false;
  }

  // en passant target square
  if (chunks[3].length > 2)
  {
    return false;
  }

  if (chunks[3].length == 1 && chunks[3] != "-")
  {
    return false;
  }

  if (chunks[3].length == 2 && !chunks[3].validPosition)
  {
    return false;
  }

  // Halfmove count
  if (!chunks[4].isNumeric)
  {
    return false;
  }

  // Move count
  if (!chunks[5].isNumeric)
  {
    return false;
  }

  // If we're through the gauntlet, it's good.
  return true;
}

string board(FEN fen)
{
  auto chunks = fen.split;
  return chunks[0];
}

Nullable!ColorPiece[][] parseBoard(FEN fen)
{
  import std.ascii;
  import std.conv;
  import std.range;
  import std.algorithm;
  import std.array;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }

  Nullable!ColorPiece[][] board;
  auto ranks = fen.board.split("/");
  foreach (rank; ranks)
  {
    Nullable!ColorPiece[] rankPieces = new Nullable!ColorPiece[8];
    uint file = 7;
    foreach (c; rank)
    {
      if (c.isDigit)
      {
        auto digit = c.to!string.to!int;
        foreach (i;iota(digit))
        {
          Nullable!ColorPiece n;
          rankPieces[file] = n;
          file--;
        }
      }
      else
      {
        rankPieces[file] = Nullable!ColorPiece(piece(c));
        file--;
      }
    }
    board ~= rankPieces;
  }

  reverse(board);
  return board;
}

ColorPiece piece(char c)
{
  switch (c)
  {
  case 'k':
    return ColorPiece(Color.Black, Piece.King);
  case 'K':
    return ColorPiece(Color.White, Piece.King);
  case 'q':
    return ColorPiece(Color.Black, Piece.Queen);
  case 'Q':
    return ColorPiece(Color.White, Piece.Queen);
  case 'b':
    return ColorPiece(Color.Black, Piece.Bishop);
  case 'B':
    return ColorPiece(Color.White, Piece.Bishop);
  case 'n':
    return ColorPiece(Color.Black, Piece.Knight);
  case 'N':
    return ColorPiece(Color.White, Piece.Knight);
  case 'r':
    return ColorPiece(Color.Black, Piece.Rook);
  case 'R':
    return ColorPiece(Color.White, Piece.Rook);
  case 'p':
    return ColorPiece(Color.Black, Piece.Pawn);
  case 'P':
    return ColorPiece(Color.White, Piece.Pawn);
  default:
    throw new Exception("Invalid piece " ~ c);
  }
}

Color activePlayer(FEN fen)
{
  import std.string;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }

  auto chunks = fen.split;
  return (chunks[1] == "w") ? Color.White : Color.Black;
}

bool[Piece][Color] castling(FEN fen)
{
  import std.string;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }

  auto chunks = fen.split;
  auto castling = chunks[2];

  bool[Piece][Color] ret;

  ret[Color.White][Piece.King] = false;
  ret[Color.White][Piece.Queen] = false;
  ret[Color.Black][Piece.King] = false;
  ret[Color.Black][Piece.Queen] = false;

  if (castling == "-")
  {
    return ret;
  }

  foreach(c; castling)
  {
    switch(c)
    {
    case 'K':
      ret[Color.White][Piece.King] = true;
      break;
    case 'k':
      ret[Color.Black][Piece.King] = true;
      break;
    case 'Q':
      ret[Color.White][Piece.Queen] = true;
      break;
    case 'q':
      ret[Color.Black][Piece.Queen] = true;
      break;
    default:
      // should never happen
      assert(0);
    }
  }
  return ret;
}

Nullable!Square enPassant(FEN fen)
{
  import std.string;
  import std.algorithm;
  import std.conv;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }

  auto chunks = fen.split;

  if (chunks[3].length == 1 && chunks[3] == "-")
  {
    return Nullable!Square();
  }

  auto squareString = chunks[3].map!toUpper.array;
  return Nullable!Square(squareString.to!Square);
}

int drawClock(FEN fen)
{
  import std.string;
  import std.conv;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }
  auto chunks = fen.split;
  return chunks[4].to!int;
}

int moveClock(FEN fen)
{
  import std.string;
  import std.conv;

  if (!fen.valid)
  {
    throw new Exception("Invalid FEN");
  }
  auto chunks = fen.split;
  return chunks[5].to!int;
}

// Invalid board
unittest
{
  auto shortOnLines = "8/8/8/8/8/8/8";
  assert(!shortOnLines.boardChunk);

  auto lineShort = "8/8/8/8/8/8/8/7";
  assert(!lineShort.boardChunk);

  auto invalidChar = "c7/8/8/8/8/8/8/8";
  assert(!invalidChar.valid);
}

// Invalid Castling availability
unittest
{
  auto tooLong = "KQkqx";
  assert(!tooLong.castlingChunk);

  auto doubleAvailable = "KKkk";
  assert(!doubleAvailable.castlingChunk);
}
