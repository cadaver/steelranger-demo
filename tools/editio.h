#ifdef __WIN32__
#include <io.h>
#include <sys/stat.h>
#include <fcntl.h>
#else
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#define O_BINARY 0
#endif

unsigned char read8(int handle)
{
    unsigned char bytes[1];
    read(handle, bytes, 1);
    return bytes[0];
}

unsigned short readle16(int handle)
{
    unsigned char bytes[2];
    read(handle, bytes, 2);
    return ((unsigned short)bytes[0]) | (((unsigned short)bytes[1]) << 8);
}

unsigned readle32(int handle)
{
    unsigned char bytes[4];
    read(handle, bytes, 4);
    return ((unsigned)bytes[0]) | (((unsigned)bytes[1]) << 8) | (((unsigned)bytes[2]) << 16) | (((unsigned)bytes[3]) << 24);
}

void write8(int handle, unsigned data)
{
  unsigned char bytes[1];

  bytes[0] = data;
  write(handle, bytes, 1);
}

void writele16(int handle, unsigned data)
{
  unsigned char bytes[2];

  bytes[0] = data;
  bytes[1] = data >> 8;
  write(handle, bytes, 2);
}

void writele32(int handle, unsigned data)
{
  unsigned char bytes[4];

  bytes[0] = data;
  bytes[1] = data >> 8;
  bytes[2] = data >> 16;
  bytes[3] = data >> 24;
  write(handle, bytes, 4);
}
