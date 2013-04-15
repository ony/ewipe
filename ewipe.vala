/* ewipe.vala
 *
 * Copyright (C) 2013 Nikolay Orlyuk
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Nikolay Orlyuk <virkony@gmail.com>
 */

void posix_failure(string subject)
{
    stderr.printf("%s failed: %s\n", subject, strerror(errno));
    Process.exit(2);
}

int main(string[] args)
{
    size_t maxSize = 0;
    for(int i = 1; i < args.length; ++i)
    {
        Posix.Stat s;
        if (Posix.stat(args[i], out s) != 0) posix_failure("stat");
        print("%s - %lu byte(s)\n", args[i], s.st_size);
        if (maxSize < s.st_size) maxSize = s.st_size;
    }
    if (maxSize == 0)
    {
        stderr.printf("Nothing to wipe (no non-empty file)\n");
        return 0;
    }

    int fdZeroes = Posix.open("/dev/zero", Posix.O_RDONLY);
    if (fdZeroes == -1) posix_failure("open");

    void *zeroes = Posix.mmap(null, maxSize, Posix.PROT_READ, Posix.MAP_SHARED, fdZeroes, 0);
    if (zeroes == null) posix_failure("mmap");
    Posix.close(fdZeroes);

    for(int i = 1; i < args.length; ++i)
    {
        string filename = args[i];
        print("wiping %s\n", filename);
        int fd = Posix.open(filename, Posix.O_WRONLY);
        if (fd == -1) posix_failure("open");
        Posix.Stat s;
        if (Posix.fstat(fd, out s) != 0) posix_failure("stat");
        for(size_t left = s.st_size; left > 0; )
        {
            ssize_t written = Posix.write(fd, zeroes, s.st_size);
            if (written == -1) posix_failure("write");
            assert(written > 0);
            left -= written;
        }
        Posix.close(fd);
    }

    return 0;
}
