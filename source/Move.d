module dhess.Move;

import dhess.Pieces;
import dhess.Position;

import std.typecons;


alias Move = Tuple!(Piece, "piece", Square, "source", Square, "destination");

