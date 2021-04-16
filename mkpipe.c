/*
 *  mkpipe - make a pipe and wait until killed
 *  Copyright (C) 2021  Oleg Nemanov, Z-Wave.Me <lego12239@yandex.ru>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#define _GNU_SOURCE
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>

#define VERSION "1.0.0"

int flags, psize;

void
process_opts(int argc, char **argv)
{
	int ret;
	char *prgname, *ptr;

	prgname = strchr(argv[0], '/');
	if (!prgname)
		prgname = argv[0];
	else
		prgname++;

	flags = 0;
	while ((ret = getopt(argc, argv, "cBs:hv")) != -1) {
		switch (ret) {
		case 'c':
			flags |= O_CLOEXEC;
			break;
		case 'B':
			flags |= O_NONBLOCK;
			break;
		case 's':
			psize = strtol(optarg, &ptr, 10);
			if (*ptr != '\0') {
				fprintf(stderr, "size must be a number\n");
				exit(1);
			}
			break;
		case 'v':
			printf("%s %s\n", prgname, VERSION);
			exit(0);
		case 'h':
		default:
			fprintf(stderr, "Usage: %s [OPTIONS]\n"
			  "Make a pipe and wait\n\n"
			  " OPTIONS:\n"
			  "  -B        create pipe with O_NONBLOCK\n"
			  "  -c        create pipe with O_CLOEXEC\n"
			  "  -s BYTES  set pipe size to BYTES\n"
			  "  -h        show this help\n"
			  "  -v        show program version\n", prgname);
			exit(1);
		}
	}
}

void
main(int argc, char **argv)
{
	int ret, fd, fds[2];
	pid_t pid;

	process_opts(argc, argv);

	/* Reserve 3 and 4 fd */
	close(3);
	close(4);
	fd = open("/dev/null", O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "open error: %s\n", strerror(errno));
		exit(1);
	}
	if (fd != 3) {
		fd = dup2(fd, 3);
		if (fd < 0) {
			fprintf(stderr, "dup2 after open error: %s\n", strerror(errno));
			exit(1);
		}
	}
	fd = open("/dev/null", O_WRONLY);
	if (fd < 0) {
		fprintf(stderr, "open error: %s\n", strerror(errno));
		exit(1);
	}
	if (fd != 4) {
		fd = dup2(fd, 4);
		if (fd < 0) {
			fprintf(stderr, "dup2 after open error: %s\n", strerror(errno));
			exit(1);
		}
	}

	/* Create a pipe */
	ret = pipe2(fds, flags);
	if (ret < 0) {
		fprintf(stderr, "pipe error: %s\n", strerror(errno));
		exit(1);
	}
	if (psize) {
		ret = fcntl(fds[0], F_SETPIPE_SZ, psize);
		if (ret < 0) {
			fprintf(stderr, "set pipe size error: %s\n", strerror(errno));
			exit(1);
		}
		ret = fcntl(fds[0], F_GETPIPE_SZ);
		if (ret < 0) {
			fprintf(stderr, "get pipe size error: %s\n", strerror(errno));
			exit(1);
		}
		if (ret < psize) {
			fprintf(stderr, "result size of pipe is smaller than requested: %d\n",
			  ret);
			exit(1);
		}
	}
	fd = dup2(fds[0], 3);
	if (fd < 0) {
		fprintf(stderr, "dup2 after pipe error: %s\n", strerror(errno));
		exit(1);
	}
	fd = dup2(fds[1], 4);
	if (fd < 0) {
		fprintf(stderr, "dup2 after pipe error: %s\n", strerror(errno));
		exit(1);
	}

	/* Signal about finish */
	pid = fork();
	if (pid < 0) {
		fprintf(stderr, "fork error: %s\n", strerror(errno));
		exit(1);
	} else if (pid > 0) {
		printf("%d", pid);
		exit(0);
	}
		
	pid = setsid();
	if (pid < 0) {
		/* Send to syslog? */
		fprintf(stderr, "setsid error: %s\n", strerror(errno));
		exit(1);
	}
	close(0);
	close(1);
	close(2);

	/* Wait for the death */
	pause();
}

