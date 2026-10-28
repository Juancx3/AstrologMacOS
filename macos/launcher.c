/*
** launcher.c - The executable inside Astrolog.app (Contents/MacOS/Astrolog).
**
** It opens Contents/Resources/astrolog.command in Terminal, which runs
** Astrolog there. It has to be a compiled program: when an app's executable
** is a shell script, macOS can't tell which processor it's for and runs the
** app under Rosetta, asking to install Rosetta on Macs that don't have it.
**
** Built by macos/Makefile, together with Astrolog.
*/

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

int main(void)
{
  char exe[PATH_MAX], real[PATH_MAX], script[PATH_MAX], *slash;
#ifdef __APPLE__
  uint32_t size = sizeof(exe);

  if (_NSGetExecutablePath(exe, &size) != 0)
    return 1;
#else
  ssize_t len = readlink("/proc/self/exe", exe, sizeof(exe) - 1);

  if (len < 0)
    return 1;
  exe[len] = '\0';
#endif
  if (realpath(exe, real) == NULL)
    return 1;

  /* .../Astrolog.app/Contents/MacOS/Astrolog ->
     .../Astrolog.app/Contents/Resources/astrolog.command */
  slash = strrchr(real, '/');
  if (slash == NULL)
    return 1;
  *slash = '\0';
  if (snprintf(script, sizeof(script), "%s/../Resources/astrolog.command",
    real) >= (int)sizeof(script))
    return 1;

  execl("/usr/bin/open", "open", "-a", "Terminal", script, (char *)NULL);
  perror("open");
  return 1;
}
