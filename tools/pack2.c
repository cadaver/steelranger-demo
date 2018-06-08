#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  int val;
  FILE *in;
  FILE *out;
  char cmd[256];
  if (argc < 3) 
  {
    printf("Invokes exomizer2.08 (forward mode + no literal sequences + max.sequence 255 bytes), strips startaddress from header. Note that Exomizer 2.08 should exist in path as 'exomizer208'.\n\nUsage: pack2 <infile> <outfile>\n");
    return 1;
  }
  
  sprintf(cmd, "exomizer208 level -M255 -c -f -o%s %s@0", "temp.bin", argv[1]);
  val = system(cmd);
  if (val > 0) return val;

  in = fopen("temp.bin", "rb");
  if (!in) return 1;
  out = fopen(argv[2], "wb");
  if (!out) return 1;
  // Skip first 2 bytes of exomized output
  fgetc(in);
  fgetc(in);
  for (;;)
  {
    int c = fgetc(in);
    if (c == EOF) break;
    fputc(c, out);
  }
  fclose(in);
  fclose(out);
  unlink("temp.bin");
  return 0;
}
