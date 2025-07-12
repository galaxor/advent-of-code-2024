using System;

namespace HelloWorld {
  class Program {

    static void Main(string[] args) {
      List<string> Board = [];

      string? line;

      while ((line = Console.ReadLine()) != null) {
        Board.Add(line);
      }

      int x, y;
      int xmases_found = 0;

      // Now the diagonal down-rights.
      for (y=0; y<=Board.Count-3; y++) {
        for (x=0; x<=Board[0].Length-3; x++) {
          if (
            ((Board[x][y] == 'M' && Board[x+1][y+1] == 'A' && Board[x+2][y+2] == 'S')
              || (Board[x][y] == 'S' && Board[x+1][y+1] == 'A' && Board[x+2][y+2] == 'M'))

            &&

            ((Board[x][y+2] == 'M' && Board[x+1][y+1] == 'A' && Board[x+2][y] == 'S')
              || (Board[x][y+2] == 'S' && Board[x+1][y+1] == 'A' && Board[x+2][y] == 'M'))

          ) {
            xmases_found += 1;
          }
        }
      }

      Console.WriteLine($"Found {xmases_found} xmases");

    }

  }
}
